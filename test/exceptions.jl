using PNML, EzXML, ..TestUtils, JET
using OrderedCollections
using PNML:
    tag, pid, xmlnode, parse_net, parse_page!, nets, page_type,
    place_type, refplace_type, transition_type, reftransition_type, arc_type,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name

"Parse `node` with `f` and expect a MalformedException with message containing `emsg`."
function test_malformed(emsg, f, node...)
    try
        f(node...)  # Splat additional parameters.
        error("expected exception message containing '$emsg`")
    catch e
        if e isa PNML.PnmlException
            @test e isa PNML.MalformedException
            @test occursin(emsg, e.msg)
        else
            rethrow(e)
        end
    end
end

@testset "missing namespace $pntd" for pntd in all_nettypes()
    emsg = r"missing namespace"
    @test_logs match_mode = :any (:warn, emsg) parse_pnml(xml"""
         <pnml><net id="1" type="foo"><page id="pg1"/></net>
         </pnml>
         """, registry())
    @test_logs match_mode = :any (:warn, emsg) parse_pnml(xml"""
          <?xml version="1.0" encoding="UTF-8"?>
          <pnml><net id="1" type="foo"><page id="pg1"/></net></pnml>""", registry())
    @test_logs match_mode = :any (:warn, emsg) parse_pnml(xml"""
          <?xml version="1.0" encoding="UTF-8"?>
          <pnml><net id="1" type="foo"><page id="pg1"/></net></pnml>""", registry())
end

@testset "malformed $pntd" for pntd in all_nettypes()
    test_malformed("does not have any <net> elements", parse_pnml,
        xml"""
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
</pnml>
""", registry())

    test_malformed("missing tool attribute", parse_pnml,
        xml"""
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net type="http://www.pnml.org/version-2009/grammar/pnmlcore" id="n1">
    <page id="pg1">
      <place id="p1"/>
      <transition id="t1"/>
      <place id="p3"/>
      <place id="p4"/>
      <place id="p5">
        <toolspecific/>
      </place>
      <place id="p6">
        <toolspecific/>
      </place>
    </page>
  </net>
  </pnml>
  """, registry())

    test_malformed("net missing type", parse_pnml,
        xml"""
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="4712">
    <page id="3">
      <place id="p2">
        <toolspecific/>
      </place>
      <arc id="a3" source="p2" target="t3"/>
      <transition id="t3"/>
    </page>
  </net>
</pnml>
""", registry())

    test_malformed("net missing type", parse_net,
        xml"""<net id="4712"> </net>""", registry())

    # Test absence of an malformed exception detection.
    @test_throws Exception test_malformed("not malformed here", parse_node,
        xml"""<toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
             <visible>true</visible> </toolspecific>""", pntd, registry())

    test_malformed("missing version attribute", parse_node,
        xml"""<toolspecific tool="de.uni-freiburg.telematik.editor">
             <visible>true</visible> </toolspecific>""", pntd, registry())

    test_malformed("missing tool attribute", parse_node,
        xml"""<toolspecific version="1.0">
             <visible>true</visible> </toolspecific>""", pntd, registry())
end


@testset "missing $pntd" for pntd in all_nettypes()

    #parse_net(xml"<net type='test'></net>", registry()) # Wrong exception debugging.
    @test_throws MissingIDException parse_net(xml"<net type='test'></net>", registry())

    pagedict = OrderedDict{Symbol, page_type(pntd)}()
    netdata = PNML.PnmlNetData(pntd)

    @test_throws MissingIDException parse_page!(pagedict, netdata, xml"<page></page>", pntd, registry())
    @test_throws MissingIDException PNML.parse_place(xml"<place></place>", pntd, registry())
    @test_throws MissingIDException PNML.parse_transition(xml"<transition></transition>", pntd, registry())
    @test_throws MissingIDException PNML.parse_arc(xml"<arc></arc>", pntd, registry())
    @test_throws MissingIDException PNML.parse_refPlace(xml"<referencePlace></referencePlace>", pntd, registry())
    @test_throws MissingIDException PNML.parse_refTransition(xml"<referenceTransition></referenceTransition>", pntd, registry())
end

@testset "graphics $pntd" for pntd in all_nettypes()
    test_malformed("missing x", parse_node,
        xml"<graphics><dimension y='2'/></graphics>", pntd, registry())
    test_malformed("missing y", parse_node,
        xml"<graphics><dimension x='1'/></graphics>", pntd, registry())

    test_malformed("missing x", parse_node,
        xml"<tokengraphics><tokenposition y='-2'/></tokengraphics>", pntd, registry())
    test_malformed("missing y", parse_node,
        xml"<tokengraphics><tokenposition x='-9'/></tokengraphics>", pntd, registry())
end

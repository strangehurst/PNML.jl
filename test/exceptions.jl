using PNML, EzXML, ..TestUtils, JET
using OrderedCollections
using PNML:
    tag, pid, xmlnode, parse_net, parse_page!, nets, page_type,
    place_type, refplace_type, transition_type, reftransition_type, arc_type,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name

const _pntd = PnmlCoreNet()

println("exceptions")
"Parse `node` with `f` and expect a MalformedException with message containing `emsg`."
function test_malformed(emsg, f, xs...)
    try
        f(xs...)
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

@testset "missing namespace" begin
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

@testset "empty name" begin
    @test_logs match_mode = :any (:warn, r"missing <text>") parse_name(xml"<name></name>", _pntd, registry())
end

@testset "malformed" begin
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
             <visible>true</visible> </toolspecific>""", _pntd, registry())

    test_malformed("missing version attribute", parse_node,
        xml"""<toolspecific tool="de.uni-freiburg.telematik.editor">
             <visible>true</visible> </toolspecific>""", _pntd, registry())

    test_malformed("missing tool attribute", parse_node,
        xml"""<toolspecific version="1.0">
             <visible>true</visible> </toolspecific>""", _pntd, registry())
end


@testset "missing id" begin
    #parse_net(xml"<net type='test'></net>", registry()) # Wrong exception debugging.
    @test_throws MissingIDException parse_net(xml"<net type='test'></net>", registry())

    pagedict = OrderedDict{Symbol, page_type(_pntd)}()
    netdata = PNML.PnmlNetData(_pntd,
                                OrderedDict{Symbol, place_type(_pntd)}(),
                                OrderedDict{Symbol, transition_type(_pntd)}(),
                                OrderedDict{Symbol, arc_type(_pntd)}(),
                                OrderedDict{Symbol, refplace_type(_pntd)}(),
                                OrderedDict{Symbol, reftransition_type(_pntd)}())

    #parse_page!(pagedict, netdata, xml"<page></page>", _pntd, registry())
    @test_throws MissingIDException parse_page!(pagedict, netdata, xml"<page></page>", _pntd, registry())

    #PNML.parse_place(xml"<place></place>", _pntd, registry())
    #PNML.parse_transition(xml"<transition></transition>", _pntd, registry())
    #PNML.parse_arc(xml"<arc></arc>", _pntd, registry())
    #PNML.parse_refPlace(xml"<referencePlace></referencePlace>", _pntd, registry())
    #PNML.parse_refTransition(xml"<referenceTransition></referenceTransition>", registry())

    @test_throws MissingIDException PNML.parse_place(xml"<place></place>", _pntd, registry())
    @test_throws MissingIDException PNML.parse_transition(xml"<transition></transition>", _pntd, registry())
    @test_throws MissingIDException PNML.parse_arc(xml"<arc></arc>", _pntd, registry())
    @test_throws MissingIDException PNML.parse_refPlace(xml"<referencePlace></referencePlace>", _pntd, registry())
    @test_throws MissingIDException PNML.parse_refTransition(xml"<referenceTransition></referenceTransition>", _pntd, registry())
end

@testset "graphics" begin
    test_malformed("missing x", parse_node,
        xml"<graphics><offset y='2'/></graphics>", _pntd, registry())
    test_malformed("missing y", parse_node,
        xml"<graphics><offset x='1'/></graphics>", _pntd, registry())

    test_malformed("missing x", parse_node,
        xml"<graphics><position y='2'/></graphics>", _pntd, registry())
    test_malformed("missing y", parse_node,
        xml"<graphics><position x='1'/></graphics>", _pntd, registry())

    test_malformed("missing x", parse_node,
        xml"<graphics><dimension y='2'/></graphics>", _pntd, registry())
    test_malformed("missing y", parse_node,
        xml"<graphics><dimension x='1'/></graphics>", _pntd, registry())

    test_malformed("missing x", parse_node,
        xml"<tokengraphics><tokenposition y='-2'/></tokengraphics>", _pntd, registry())
    test_malformed("missing y", parse_node,
        xml"<tokengraphics><tokenposition x='-9'/></tokengraphics>", _pntd, registry())
end

using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid, xmlnode, parse_net, nets, firstpage
#using .PnmlIDRegistrys

"Parse `node` with `f` and expect a MalformedException with message containing `emsg`."
function test_malformed(emsg, f, node)
    try
        n = f(node, PnmlIDRegistry())
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
         """, PnmlIDRegistry())
    @test_logs match_mode = :any (:warn, emsg) parse_pnml(xml"""
          <?xml version="1.0" encoding="UTF-8"?>
          <pnml><net id="1" type="foo"><page id="pg1"/></net></pnml>""", PnmlIDRegistry())
    @test_logs match_mode = :any (:warn, emsg) parse_pnml(xml"""
          <?xml version="1.0" encoding="UTF-8"?>
          <pnml><net id="1" type="foo"><page id="pg1"/></net></pnml>""", PnmlIDRegistry())
end

@testset "empty name" begin
    @test_logs match_mode = :any (:warn, r"missing <text>") parse_node(xml"<name></name>", PnmlIDRegistry())
end

@testset "malformed" begin
    test_malformed(
        "does not have any <net> elements",
        parse_pnml,
        xml"""
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
</pnml>
"""
    )
    test_malformed(
        "missing tool attribute",
        parse_pnml,
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
  """
    )

    test_malformed(
        "net missing type",
        parse_pnml,
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
"""
    )

    test_malformed("net missing type", parse_net, xml"""<net id="4712"> </net>""")

    # Test absence of an malformed exception detection.
    @test_throws Exception test_malformed("not malformed here", parse_node,
        xml"""<toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
             <visible>true</visible> </toolspecific>""")

    test_malformed("missing version attribute", parse_node,
        xml"""<toolspecific tool="de.uni-freiburg.telematik.editor">
             <visible>true</visible> </toolspecific>""")

    test_malformed("missing tool attribute", parse_node,
        xml"""<toolspecific version="1.0">
             <visible>true</visible> </toolspecific>""")
end

@testset "missing id" begin
    @test_throws MissingIDException parse_net(xml"<net type='test'></net>", PnmlIDRegistry())
    @test_throws MissingIDException parse_node(xml"<page></page>", PnmlIDRegistry())
    @test_throws MissingIDException parse_node(xml"<place></place>", PnmlIDRegistry())
    @test_throws MissingIDException parse_node(xml"<transition></transition>", PnmlIDRegistry())
    @test_throws MissingIDException parse_node(xml"<arc></arc>", PnmlIDRegistry())
    @test_throws MissingIDException parse_node(xml"<referencePlace></referencePlace>", PnmlIDRegistry())
    @test_throws MissingIDException parse_node(xml"<referenceTransition></referenceTransition>", PnmlIDRegistry())
end

@testset "graphics" begin
    test_malformed("missing x", parse_node, xml"<graphics><offset y='2'/></graphics>")
    test_malformed("missing y", parse_node, xml"<graphics><offset x='1'/></graphics>")

    test_malformed("missing x", parse_node, xml"<graphics><position y='2'/></graphics>")
    test_malformed("missing y", parse_node, xml"<graphics><position x='1'/></graphics>")

    test_malformed("missing x", parse_node, xml"<graphics><dimension y='2'/></graphics>")
    test_malformed("missing y", parse_node, xml"<graphics><dimension x='1'/></graphics>")

    test_malformed("missing x", parse_node, xml"<tokengraphics><tokenposition y='-2'/></tokengraphics>")
    test_malformed("missing y", parse_node, xml"<tokengraphics><tokenposition x='-9'/></tokengraphics>")
end

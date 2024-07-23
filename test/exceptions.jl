using PNML, ..TestUtils, JET
using OrderedCollections

println("EXCEPTIONS")

@testset "showerr" begin
    e1 = MissingIDException("test showerr")::PnmlException
    e2 = MalformedException("test showerr")::PnmlException
    @test sprint(showerror,e1) != sprint(showerror,e2)
    Base.redirect_stdio(stdout=devnull, stderr=devnull) do
        @test_logs showerror(stdout,e1)
        @test_logs showerror(stdout,e2)
        @test_logs showerror(stderr,e1)
        @test_logs showerror(stderr,e2)
    end
end

@testset "missing namespace $pntd" for pntd in core_nettypes()
    @test_logs(match_mode=:any, (:warn, r"missing namespace"),
        parse_pnml(xml"""<pnml><net id="N1" type="foo"><page id="pg1"/></net></pnml>"""))

    @test_logs(match_mode=:any, (:warn, "pnml missing namespace"),
        parse_pnml(xml"""<?xml version="1.0" encoding="UTF-8"?>
                        <pnml><net id="N1" type="foo"><page id="pg1"/></net></pnml>"""))
end

@testset "malformed $pntd" for pntd in core_nettypes()
    @test_throws("MalformedException: <pnml> does not have any <net> elements",
        parse_pnml(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml"></pnml>"""))

    @test_throws("MalformedException: toolspecific missing tool attribute",
        parse_pnml(xml"""
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
    """))

    @test_throws("MalformedException: net missing type",
        parse_pnml(xml"""
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
"""))

    @with PNML.idregistry => registry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[]; ids=(:NN,))
        @test_throws("MalformedException: net missing type",
             parse_net(xml"""<net id="4712"> </net>"""))
    end
end

@testset "missing id $pntd" for pntd in core_nettypes()
    @with PNML.idregistry => registry() PNML.DECLDICT => PNML.DeclDict() begin

        PNML.fill_nonhl!(PNML.DECLDICT[]; ids=(:NN,))
        @test_throws "MissingIDException: net" parse_net(xml"<net type='test'></net>")

        pagedict = OrderedDict{Symbol, page_type(pntd)}()
        netdata = PNML.PnmlNetData(pntd)
        netsets = PNML.PnmlNetKeys()

        @test_throws r"^MissingIDException: page" PNML.parse_page!(pagedict, netdata, netsets, xml"<page></page>", pntd; ids=(:NN,))
        @test_throws r"^MissingIDException: place" PNML.parse_place(xml"<place></place>", pntd; ids=(:NN,))
        @test_throws r"^MissingIDException: transition" PNML.parse_transition(xml"<transition></transition>", pntd; ids=(:NN,))
        @test_throws r"^MissingIDException: arc" PNML.parse_arc(xml"<arc></arc>", pntd; ids=(:NN,), netdata=PNML.PnmlNetData(pntd))
        @test_throws r"^MissingIDException: referencePlace" PNML.parse_refPlace(xml"<referencePlace></referencePlace>", pntd; ids=(:NN,))
        @test_throws r"^MissingIDException: referenceTransition" PNML.parse_refTransition(xml"<referenceTransition></referenceTransition>", pntd; ids=(:NN,))
    end
end

@testset "check_nodename" begin
    @test_throws "ArgumentError: element name wrong, expected bar, got foo" PNML.Parser.check_nodename(xml"<foo></foo>", "bar")
end

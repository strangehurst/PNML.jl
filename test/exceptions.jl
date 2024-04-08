using PNML, EzXML, ..TestUtils, JET
using OrderedCollections

println("EXCEPTIONS")

@testset "showerr" begin
    e1 = MissingIDException("test showerr")
    e2 = MalformedException("test showerr")
    @test e1 isa PnmlException
    @test e2 isa PnmlException
    @test sprint(showerror,e1) != sprint(showerror,e2)
    Base.redirect_stdio(stdout=devnull, stderr=devnull) do
        @test_logs showerror(stdout,e1)
        @test_logs showerror(stdout,e2)
        @test_logs showerror(stderr,e1)
        @test_logs showerror(stderr,e2)
    end
end

@testset "missing namespace $pntd" for pntd in core_nettypes()
    empty!(PNML.TOPDECLDICTIONARY)
    #@show collect(keys(PNML.TOPDECLDICTIONARY))
    @test isempty(PNML.TOPDECLDICTIONARY) #

    @test_logs(match_mode=:any, (:warn, r"missing namespace"),
        parse_pnml(xml"""<pnml><net id="N1" type="foo"><page id="pg1"/></net></pnml>"""))

    empty!(PNML.TOPDECLDICTIONARY)
    @test_logs(match_mode=:any, (:warn, "pnml missing namespace"),
        parse_pnml(xml"""<?xml version="1.0" encoding="UTF-8"?>
                        <pnml><net id="N1" type="foo"><page id="pg1"/></net></pnml>"""))
end

@testset "malformed $pntd" for pntd in core_nettypes()
    empty!(PNML.TOPDECLDICTIONARY)
    @test_throws("MalformedException: <pnml> does not have any <net> elements",
        parse_pnml(xml"""<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml"></pnml>"""))

    empty!(PNML.TOPDECLDICTIONARY)
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
    empty!(PNML.TOPDECLDICTIONARY)

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

    @test_throws "MalformedException: net missing type" parse_net(xml"""<net id="4712"> </net>""", registry())
end

@testset "missing id $pntd" for pntd in core_nettypes()

    @test_throws "MissingIDException: net" parse_net(xml"<net type='test'></net>", registry())

    empty!(PNML.TOPDECLDICTIONARY)
    pagedict = OrderedDict{Symbol, page_type(pntd)}()
    netdata = PNML.PnmlNetData(pntd)
    netsets = PNML.PnmlNetKeys()
    PNML.TOPDECLDICTIONARY[:N] = PNML.DeclDict()

    @test_throws r"^MissingIDException: page" PNML.parse_page!(pagedict, netdata, netsets, (:N,), xml"<page></page>", pntd, registry())
    @test_throws r"^MissingIDException: place" PNML.parse_place((:NN,), xml"<place></place>", pntd, registry())
    @test_throws r"^MissingIDException: transition" PNML.parse_transition((:NN,), xml"<transition></transition>", pntd, registry())
    @test_throws r"^MissingIDException: arc" PNML.parse_arc((:NN,), xml"<arc></arc>", pntd, registry())
    @test_throws r"^MissingIDException: referencePlace" PNML.parse_refPlace((:NN,), xml"<referencePlace></referencePlace>", pntd, registry())
    @test_throws r"^MissingIDException: referenceTransition" PNML.parse_refTransition((:NN,), xml"<referenceTransition></referenceTransition>", pntd, registry())
end

@testset "check_nodename" begin
    @test_throws "ArgumentError: element name wrong, expected bar, got foo" PNML.check_nodename(xml"<foo></foo>", "bar")
end

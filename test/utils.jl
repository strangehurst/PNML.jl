using PNML, ..TestUtils, JET, InteractiveUtils, XMLDict
import EzXML

@testset "CONFIG" begin
    @show PNML.CONFIG
end

@testset "_evaluate" begin
    f() = "testing"
    @test PNML._evaluate(f) == "testing"
end

@testset "ExXML" begin
    @test_throws ArgumentError xmlroot("")
    @test_throws "empty XML string" xmlroot("")
end

@testset "getfirst XMLNode" begin
    node = xml"""<test>
        <a name="a1"/>
        <a name="a2"/>
        <a name="a3"/>
        <c name="c1"/>
        <c name="c2"/>
    </test>
    """
    @test_call target_modules=target_modules firstchild(node, "a")
    @test_call EzXML.nodename(firstchild(node, "a"))
    @test EzXML.nodename(firstchild(node, "a")) == "a"
    @test firstchild(node, "a")["name"] == "a1"
    @test firstchild(node, "b") === nothing
    @test EzXML.nodename(firstchild(node, "c")) == "c"

    @test_call target_modules=target_modules allchildren(node, "a")
    @test map(c->c["name"], @inferred(allchildren(node, "a"))) == ["a1", "a2", "a3"]
end





@testset "default_condition($pntd)" for pntd in all_nettypes(ishighlevel)
    c = default_condition(pntd)::PNML.Condition #! TestUtils, Base export Condition
    println("default_condition($pntd) = ", c)
    cv = value(c)::Bool
    #@test sortof(c) isa BoolSort
    @test cv == true
end

@testset "default_inscription($pntd)" for pntd in all_nettypes()
    i = default_inscription(pntd)
    println("default_inscription($pntd) = ", i)
end

@testset "default_typeusersort($pntd)" for pntd in all_nettypes()
    t = default_typeusersort(pntd; ids=(:typeusersort,))::UserSort
    println("default_typeusersort($pntd) = ", t)
end

@testset "rate_value_type($pntd)" for pntd in all_nettypes()
    r = rate_value_type(pntd)
    println("rate_value_type($pntd) = ", r)
    @test r == eltype(RealSort)
end

@testset "PnmlNetData($pntd)" for pntd in core_nettypes() # to limit number of tests
    pnd = PnmlNetData(pntd)
    @test isempty(PNML.placedict(pnd))
    @test isempty(PNML.transitiondict(pnd))
    @test isempty(PNML.arcdict(pnd))
    @test isempty(PNML.refplacedict(pnd))
    @test isempty(PNML.reftransitiondict(pnd))
end

@testset "PnmlNetKeys() for $pntd" for pntd in core_nettypes() # to limit number of tests
    pns = PnmlNetKeys()
    @test isempty(PNML.page_idset(pns))
    @test isempty(PNML.place_idset(pns))
    @test isempty(PNML.transition_idset(pns))
    @test isempty(PNML.arc_idset(pns))
    @test isempty(PNML.reftransition_idset(pns))
    @test isempty(PNML.refplace_idset(pns))
end

@testset "predicates for $pntd" for pntd in all_nettypes()
    @test Iterators.only(Iterators.filter(==(true), (isdiscrete(pntd), ishighlevel(pntd), iscontinuous(pntd))))
    tp = typeof(pntd) # translate from singleton to type
    @test Iterators.only(Iterators.filter(==(true), (isdiscrete(tp), ishighlevel(tp), iscontinuous(tp))))
end

using PNML: pnmltype_map, default_pntd_map
@testset "add_nettype" begin
    #default_pntd_map # string -> symbol
    #pnmltype_map # symbol -> PnmlType
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :pnmlcore, PnmlCoreNet())
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :hlcore, HLCoreNet())
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :ptnet, PTNet())
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :hlnet, HLPNG())
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :pt_hlpng, PT_HLPNG())
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :symmetric, SymmetricNet())
    @test_logs (:info, r"^updating mapping") PNML.add_nettype!(pnmltype_map, :continuous, ContinuousNet())

    @test_logs (:info, r"^adding mapping") PNML.add_nettype!(pnmltype_map, :newpntd, PnmlCoreNet())
    @test :newpntd in keys(pnmltype_map)
    @test pnmltype_map[:newpntd] === PnmlCoreNet()
    @show pnmltype_map
end

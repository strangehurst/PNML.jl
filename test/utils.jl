using PNML, ..TestUtils, JET, InteractiveUtils
import EzXML
using PNML: Maybe, getfirst, firstchild, allchildren,
    ishighlevel, PnmlTypeDefs,
    page_type, place_type, transition_type, arc_type,
    marking_type, inscription_type, condition_type,
    Term, default_bool_term, default_zero_term, default_one_term,
    value, condition_value_type, rate_value_type, term_value_type,
    tag,
    BoolSort, IntegerSort, RealSort,
    Condition, default_condition,
    default_inscription, default_marking, default_sort, default_sorttype,
    AbstractSort, BoolSort, DotSort, IntegerSort, NaturalSort, PositiveSort,
    MultisetSort, ProductSort, RealSort, UserSort,
    SortType,
    PnmlNetData, PnmlNetKeys, all_nettypes, ishighlevel, isdiscrete, iscontinuous


@testset "getfirst iteratible" begin
    v = [string(i) for i in 1:9]
    @test_call getfirst(==("3"), v)
    @test "3" == @inferred Maybe{String} getfirst(==("3"), v)
    @test nothing === @inferred Maybe{String} getfirst(==("33"), v)
end

@testset "ExXML" begin
    @test_throws ArgumentError xmlroot("")
    @test_throws "empty XML string" xmlroot("")
    # This kills the testset. Macros cannot throw?
    #@test_throws( ArgumentError, xml"")

    @test_throws MethodError EzXML.namespace(nothing)
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
    @test_call target_modules=target_modules firstchild("a", node)
    @test_call EzXML.nodename(firstchild("a", node))
    @test EzXML.nodename(firstchild("a", node)) == "a"
    @test firstchild("a", node)["name"] == "a1"
    @test firstchild("b", node) === nothing
    @test EzXML.nodename(firstchild("c", node)) == "c"

    @test_call target_modules=target_modules allchildren("a", node)
    @test map(c->c["name"], @inferred(allchildren("a", node))) == ["a1", "a2", "a3"]
end

@testset "types for $pntd" for pntd in all_nettypes()
    if noisy
        @show pntd
        @show page_type(pntd)
        @show place_type(pntd) transition_type(pntd) arc_type(pntd)
        @show marking_type(pntd) inscription_type(pntd) condition_type(pntd)

        @show default_bool_term(pntd) typeof(default_bool_term(pntd))
        @show default_zero_term(pntd) typeof(default_zero_term(pntd))
        @show default_one_term(pntd) typeof(default_one_term(pntd))

        @show condition_value_type(pntd)
        @show rate_value_type(pntd)
    end
    b = default_bool_term(pntd)
    @test b isa Term
    @test value(b) isa eltype(BoolSort)
    @test tag(b) === :bool
    @test value(b) == true

    @test value(default_zero_term(pntd)) == zero(eltype(term_value_type(pntd)))
    z = default_zero_term(pntd)
    @test z isa Term
    @test value(z) isa eltype(term_value_type(pntd))
    @test tag(z) === :zero
    @test value(z) == zero(term_value_type(pntd))

    @test value(default_one_term(pntd)) == one(eltype(term_value_type(pntd)))
    b = default_one_term(pntd)
    @test b isa Term
    @test value(b) isa eltype(term_value_type(pntd))
    @test tag(b) === :one
    @test value(b) == one(term_value_type(pntd))

    @test rate_value_type(pntd) == eltype(RealSort)
end

@testset "condition $pntd" for pntd in all_nettypes(ishighlevel)
    if noisy
        @show pntd default_condition(pntd)  typeof(default_condition(pntd))
        @show default_bool_term(pntd) typeof(default_bool_term(pntd))
    end
    @test default_bool_term(pntd) isa Term
    @test default_condition(pntd)  isa Condition #(PNML.default_bool_term(pntd))
end

@testset "net data for $pntd" for pntd in all_nettypes()
    pnd = PnmlNetData(pntd)
    @test isempty(PNML.placedict(pnd))
    @test isempty(PNML.transitiondict(pnd))
    @test isempty(PNML.arcdict(pnd))
    @test isempty(PNML.refplacedict(pnd))
    @test isempty(PNML.reftransitiondict(pnd))
end

@testset "key sets for $pntd" for pntd in all_nettypes()
    pns = PnmlNetKeys()
    @test isempty(PNML.page_idset(pns))
    @test isempty(PNML.place_idset(pns))
    @test isempty(PNML.transition_idset(pns))
    @test isempty(PNML.arc_idset(pns))
    @test isempty(PNML.reftransition_idset(pns))
    @test isempty(PNML.refplace_idset(pns))
end

@testset "predicates for $pntd" for pntd in all_nettypes()
    #@show pntd isdiscrete(pntd) ishighlevel(pntd) iscontinuous(pntd)
    @test Iterators.only(Iterators.filter(==(true),
                         (isdiscrete(pntd), ishighlevel(pntd), iscontinuous(pntd))))
end

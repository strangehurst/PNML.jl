using PNML, ..TestUtils, JET, InteractiveUtils, XMLDict
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

@testset "CONFIG" begin
    @show PNML.CONFIG
end

@testset "_evaluate" begin
    f() = "testing"
    @test PNML._evaluate(f) == "testing"
end

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
        #TODO complete
        @show place_type(pntd) transition_type(pntd) arc_type(pntd)
        @show marking_type(pntd) inscription_type(pntd) condition_type(pntd)

        @show default_bool_term(pntd) typeof(default_bool_term(pntd))
        @show default_zero_term(pntd) typeof(default_zero_term(pntd))
        @show default_one_term(pntd) typeof(default_one_term(pntd))

        @show condition_value_type(pntd)
        @show rate_value_type(pntd)
    end
    b = default_bool_term(pntd)::PNML.BooleanConstant
    @test value(b) isa eltype(BoolSort)
    @test value(b) == true

    @test value(default_zero_term(pntd)) == zero(eltype(term_value_type(pntd)))
    z = default_zero_term(pntd)::PNML.NumberConstant
    @test z isa AbstractTerm
    @test value(z) isa eltype(term_value_type(pntd))
    @test value(z) == zero(term_value_type(pntd))

    @test value(default_one_term(pntd)) == one(eltype(term_value_type(pntd)))
    b = default_one_term(pntd)::PNML.NumberConstant
    @test b isa AbstractTerm
    @test value(b) isa eltype(term_value_type(pntd))
    @test value(b) == one(term_value_type(pntd))

    @test rate_value_type(pntd) == eltype(RealSort)
end

@testset "condition $pntd" for pntd in all_nettypes(ishighlevel)
    @test default_bool_term(pntd) isa AbstractTerm
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
    @test Iterators.only(Iterators.filter(==(true), (isdiscrete(pntd), ishighlevel(pntd), iscontinuous(pntd))))
    tp = typeof(pntd)
    @test Iterators.only(Iterators.filter(==(true), (isdiscrete(tp), ishighlevel(tp), iscontinuous(tp))))
    #@show isdiscrete(tp), ishighlevel(tp), iscontinuous(tp)
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
end

using PNML: DictType, XDVT, XDVT2
using XMLDict, OrderedCollections
const ODT = OrderedDict{Union{Symbol, String}, Any}
@testset "XMLDict" begin
    @show DictType XDVT
    # @show xd = xml_dict(xml"""<t/>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t attr="avalue" />""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)

    # @show xd = xml_dict(xml"""<t></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t> text </t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t>text</t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)

    # @show xd = xml_dict(xml"""<t attr="avalue" ></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t attr="avalue" > text </t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t attr="avalue" >text</t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t attr="" ></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)

    # @show xd = xml_dict(xml"""<t><u/></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t><u></u></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)

    # @show xd = xml_dict(xml"""<t><u>1</u><v>2</v></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
    # @show xd = xml_dict(xml"""<t><u></u></t>""", ODT; strip_text=true) typeof(xd)
    # #dump(xd)
end

# @testset "show DictType" begin
#     println()
#     @show DictType() typeof(DictType())
#     @show DictType(:foo => "bar")
#     @show DictType(:foo => "bar", :baz => "boo")
#     @show DictType(:foo => "bar", :baz => "boo", :three => "three")
#     @show DictType(:foo => "bar", :baz => "boo", :three => "three", :four => "four")
#     @show d = DictType(:foo => "bar", :baz => [:a => "one", :b => "two"])
#     @show d = DictType(:foo => "bar", :baz => [DictType(:a => "one"), DictType(:b => "two")])
#     @show d = DictType(:foo => "bar", :baz => (DictType(:a => "one"), DictType(:b => "two")))
#     println()
# end

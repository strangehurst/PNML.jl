using PNML, ..TestUtils, JET, InteractiveUtils, XMLDict, OrderedCollections
using SciMLLogging: SciMLLogging, @SciMLMessage
import EzXML

@testset "CONFIG" begin
    @show PNML.CONFIG[]
    #@SciMLMessage  repr(PNML.CONFIG[]) PNML.verbose :information :options
end

@testset "ExXML" begin
    @test_throws ArgumentError xml""
    @test_throws "empty XML string" xml""
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

ctx = PNML.parser_context()

@testset "default(Condition, $pntd)" for pntd in PnmlTypes.all_nettypes()
    c = Labels.default(Labels.Condition, pntd; ctx.ddict)::Labels.Condition
    @test c() == true
end

#println()
@testset "default inscription $pntd" for pntd in PnmlTypes.all_nettypes()
    placetype = if ishighlevel(pntd)
        SortType("dummy", NamedSortRef(:dot), nothing, nothing, ctx.ddict)
    elseif iscontinuous(pntd)
        SortType("dummy", NamedSortRef(:real), nothing, nothing, ctx.ddict)
    elseif isdiscrete(pntd)
        SortType("dummy", NamedSortRef(:positive), nothing, nothing, ctx.ddict)
    else
        error("pntd not known")
    end
    i = @inferred Inscription Labels.default(Inscription, pntd, placetype; ctx.ddict)
    #println("default(Inscription($pntd) = ", i)
end

@testset "value_type(Rate, $pntd)" for pntd in PnmlTypes.all_nettypes()
    r = PNML.value_type(Rate, pntd)
    #println("value_type(Rate, $pntd) = ", r)
    @test r == eltype(RealSort) == Float64
end

#println()
@testset "PnmlNetData()" for pntd in PnmlTypes.core_nettypes() # to limit number of tests
    pnd = PnmlNetData()
    @test isempty(PNML.placedict(pnd))
    @test isempty(PNML.transitiondict(pnd))
    @test isempty(PNML.arcdict(pnd))
    @test isempty(PNML.refplacedict(pnd))
    @test isempty(PNML.reftransitiondict(pnd))

    @test nplaces(pnd) == 0
    @test ntransitions(pnd) == 0
    @test narcs(pnd) == 0
    @test nreftransitions(pnd) == 0
    @test nrefplaces(pnd) == 0

    @test valtype(PNML.placedict(pnd)) isa DataType
    @test valtype(PNML.transitiondict(pnd)) isa DataType
    @test valtype(PNML.arcdict(pnd)) isa DataType
    @test valtype(PNML.refplacedict(pnd)) isa DataType
    @test valtype(PNML.reftransitiondict(pnd)) isa DataType

    od = OrderedDict{Symbol,Symbol}()
    @test valtype(od) isa DataType
end
#println()
@testset "predicates for $pntd" for pntd in PnmlTypes.all_nettypes()
    @test Iterators.only(Iterators.filter(==(true), (PnmlTypes.isdiscrete(pntd), ishighlevel(pntd), iscontinuous(pntd))))
    tp = typeof(pntd) # translate from singleton to type
    @test Iterators.only(Iterators.filter(==(true), (PnmlTypes.isdiscrete(tp), ishighlevel(tp), iscontinuous(tp))))
end

@testset "add_nettype" begin
    add_type! = PnmlTypes.add_nettype!
    typemap   = PnmlTypes.pnmltype_map
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :pnmlcore, PnmlCoreNet())
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :hlcore, HLCoreNet())
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :ptnet, PTNet())
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :hlnet, HLPNG())
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :pt_hlpng, PT_HLPNG())
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :symmetric, SymmetricNet())
    @test_logs (:info, r"^updating mapping") add_type!(typemap, :continuous, ContinuousNet())

    @test_logs (:info, r"^adding mapping") add_type!(typemap, :newpntd, PnmlCoreNet())
    @test :newpntd in keys(typemap)
    @test typemap[:newpntd] === PnmlCoreNet()
    @show typemap
end

@testset "sortref" begin
    @test sortref(1) == NamedSortRef(:integer)
    @test sortref(0x1) == NamedSortRef(:natural)
    @test sortref(0x1234) == NamedSortRef(:natural)
    @test sortref(0x12345678) == NamedSortRef(:natural)
    @test sortref(0x1234567812345678) == NamedSortRef(:natural)
    @test sortref(1.0) == NamedSortRef(:real)
end

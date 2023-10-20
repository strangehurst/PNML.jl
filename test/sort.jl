using PNML, ..TestUtils, JET, InteractiveUtils
import EzXML
using PNML: Maybe, getfirst, firstchild, allchildren,
    ishighlevel, PnmlTypeDefs,
    page_type, place_type, transition_type, arc_type,
    marking_type, inscription_type, condition_type,
    Term, default_bool_term, default_zero_term, default_one_term,
    value, condition_value_type, rate_value_type, term_value_type, tag,
    BoolSort, IntegerSort, RealSort,
    Condition, default_condition, default_inscription, default_marking, default_sort,
    AbstractSort, BoolSort, DotSort, IntegerSort, NaturalSort, PositiveSort,
    MultisetSort, ProductSort, RealSort, UserSort,
    default_sorttype, SortType

@testset "exception for Any" begin
    pntd = "this is not valid" # counts as `::Any`
    @test_throws ErrorException default_condition(pntd)
    @test_throws ErrorException default_inscription(pntd)
    @test_throws ErrorException default_marking(pntd)
    @test_throws ErrorException default_sort(pntd)
    @test_throws ErrorException default_sorttype(pntd)
    @test_throws ArgumentError default_bool_term(pntd)
end

using Printf
@testset "sorts for $pntd" for pntd in all_nettypes()
    #@show maximum((length  ∘ repr), InteractiveUtils.subtypes(AbstractSort))

    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show pntd default_sort(pntd)
        for sort in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
            @printf "%-20s %-20s %-20s\n" sort eltype(sort) sort()
        end
    end
    for sort in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
        st = @inferred SortType("test", sort())
        @test PNML.type(st) <: sort
        st2 = @inferred SortType(sort())
        @test PNML.type(st2) <: sort
    end
end

@testset "equal sorts" begin
    a = PNML.BoolSort()
    b = PNML.DotSort()
    @test !PNML.equals(a, b)
    @test PNML.equals(a, a)

    for sort1 in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
        for sort2 in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
            @test PNML.equals(sort1(), sort2()) isa Bool # mix of true and false
        end
    end
end

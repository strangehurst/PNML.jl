module Sorts
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
import Multisets: Multisets, Multiset
using PNML
import PNML: sortof, sortelements, basis, value, _evaluate, tag, pid
using PNML: DeclDict, named_sort, DECLDICT, indent, inc_indent

"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`PNML.Labels.SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml specification sometimes uses overlapping language.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations, permutations and dots.
And partitions.

The `eltype` is expected to be a concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.

# Extras

Notes:
- `NamedSort` is a Declarations.SortDeclaration
[`PNML.PnmlTypeDefs.HLPNG`](@ref) adds [`PNML.Declarations.ArbitrarySort`](@ref).
- `UserSort` holds the id symbol of a `NamedSort`.
- Here 'type' means a 'term' from the many-sorted algebra.
- We use sorts even for non-high-level nets.
- Expect `eltype(::AbstractSort)` to return a concrete subtype of `Number`.
"""
abstract type AbstractSort end

include("sorts.jl")
include("dots.jl")
include("enumerations.jl")
include("lists.jl")
include("numbers.jl")
include("strings.jl")

export AbstractSort, BoolSort, UserSort, ProductSort, MultisetSort,
        DotSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort,
        CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort,
        ListSort, StringSort,
        DotConstant, FiniteIntRangeConstant,
        TupleSort, NullSort
export equalSorts, multisetsort,
    integersort, naturalsort, positivesort, realsort, nullsort,
    equals, start, stop

end # module Sorts

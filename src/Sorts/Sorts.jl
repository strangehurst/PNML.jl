module Sorts
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using NamedTupleTools
import Multisets: Multisets, Multiset
using Logging, LoggingExtras

using PNML
using PNML: DeclDict

import PNML: sortof, sortref, sortelements, sortdefinition, basis
import PNML: value, term, tag, pid, refid, usersort, namedsort

export AbstractSort, UserSort, MultisetSort, ProductSort
export DotSort,  BoolSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort
export EnumerationSort, CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort
export ListSort, StringSort


"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`PNML.Labels.SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml specification sometimes uses overlapping language.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations, permutations, dots and partitions.

And more sorts for HLPNG: integer, strings, list

With additions we made: real.

Oh, also ArbitrarySorts.

The `eltype` is expected to be a
concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.

# Extras

Notes:
- `NamedSort` is a Declarations.SortDeclaration
[`PNML.PnmlTypes.HLPNG`](@ref) adds [`PNML.Declarations.ArbitrarySort`](@ref).
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

end # module Sorts

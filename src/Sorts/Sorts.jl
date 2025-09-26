module Sorts
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using Logging, LoggingExtras
using Moshi.Match: @match
using SciMLLogging: @SciMLMessage

import Base: eltype
import AutoHashEquals: @auto_hash_equals
import Multisets: Multisets, Multiset

using PNML
using PNML: DeclDict
using PNML: multisetsorts, productsorts
using PNML: AbstractSort

import PNML: sortof, sortref, sortelements, sortdefinition, basis
import PNML: value, term, tag, pid, refid, usersort, namedsort
import PNML: fill_sort_tag!

export AbstractSort, UserSort, MultisetSort, ProductSort
export DotSort, BoolSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort
export EnumerationSort, CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort
export ListSort, StringSort
export make_sortref


"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`PNML.Labels.SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml standard sometimes uses overlapping language.

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

include("sorts.jl")
include("dots.jl")
include("enumerations.jl")
include("lists.jl")
include("numbers.jl")
include("strings.jl")


# # These two sorts are not used in variable declarations.
# # They do not add a name to the contained sorts (or sortrefs).
# # Add a dictionary accessor argument.
fill_sort_tag!(ctx, tag, sort::ProductSort) = fill_sort_tag!(ctx, tag, sort, productsorts)::SortRef
fill_sort_tag!(ctx, tag, sort::MultisetSort) = fill_sort_tag!(ctx, tag, sort, multisetsorts)::SortRef

#
"""
    make_sortref(parse_context, dict, sort, seed, id, name) ->  SortRef`

 - `dict` is a method/callable that returns an AbstractDict (in a DeclDict).
 - `sort` ia a concrete sort that is to be in `dict`.
 - `seed` is passed to `gensym` if `id` is `nothing` and no `sort` is already in `dict`.
 - `id` is a `Symbol` and the string `name` are `nothing` and "" unless there is a wrapper providing such information,

Uses `fill_sort_tag!`.

Return concrete SortRef matching `dict`, wrapping `id`.
"""
function make_sortref(parse_context, dict::Base.Callable, sort, seed, id, name)
    @show sort
    id2 = PNML.find_valuekey(dict(parse_context.ddict), sort) # in make_sortref
    if isnothing(id2) # Did not find existing  namedsort
        if isnothing(id) # no enclosing provided name/id
            @show id = gensym(seed) # Invent REFID
        end
    end
    # fill_sort_tag! will not overwrite existing, returns SortRef
    sr = fill_sort_tag!(parse_context, id, sort, dict)::SortRef # in make_sortref
    return sr
end

end # module Sorts

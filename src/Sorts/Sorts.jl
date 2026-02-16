"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See [`PNML.Labels.SortType`](@ref).

NamedSort is a _SortDecl_ (SortDeclaration) that gives a name and id to a _Sort_.

The pnml standard sometimes uses overlapping language. And explains little, expecting one
to be knowledgeable about colored petri nets.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations,
products, dots and partitions.

And more sorts for HLPNG: integer, strings, list

With additions we made: real.

Oh, also ArbitrarySorts.

#! XXX The `eltype` is expected to be a
concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.

# Extras

Notes:
  - `NamedSort` is a Declarations.SortDeclaration
  - [`PNML.PnmlTypes.HLPNG`](@ref) adds [`PNML.Declarations.ArbitrarySort`](@ref).
  - `PartitionSort` is called "Partition" in the standard.
  - `SortRefImpl` holds the id symbol of a concrete sort.
  - We use sorts even for non-high-level nets.
  - Expect `eltype(::AbstractSort)` to return a concrete subtype of `Number`.
"""
module Sorts

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using Logging, LoggingExtras
using Moshi.Match: @match
using Moshi.Data: isa_variant, variant_type
using SciMLLogging: @SciMLMessage

import Base: eltype
import AutoHashEquals: @auto_hash_equals
import Multisets: Multisets, Multiset

using PNML
using PNML: DeclDict, multisetsorts
using PNML: AbstractSort, namedsort, namedsorts, productsort, productsorts

import PNML: sortof, sortref, sortelements, sortdefinition, basis
import PNML: value, term, tag, pid, refid
import PNML: fill_sort_tag!

export AbstractSort, MultisetSort, ProductSort
export DotSort, BoolSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort
export EnumerationSort, CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort
export ListSort, StringSort
export make_sortref

include("sorts.jl")
include("dots.jl")
include("enumerations.jl")
include("lists.jl")
include("numbers.jl")
include("strings.jl")


#
"""
    make_sortref(net, dict, sort, seed, id, name) ->  AbstractSortRef`

 - `dict` is a method/callable that returns an AbstractDict a DeclDict attached to `net`.
 - `sort` ia a concrete sort that is to be in `dict`.
 - `seed` is passed to `gensym` if `id` is `nothing` and no `sort` is already in `dict`.
 - `id` is a `Symbol` and the string `name` are `nothing` and "" unless there is a wrapper providing such information,

Uses `fill_sort_tag!`.

Return concrete AbstractSortRef matching `dict`, wrapping `id`.
"""
function make_sortref(net, dict::Base.Callable, sort, seed, sortid, name=nothing)
    #!@show sort dict seed sortid
    id2 = PNML.find_valuekey(dict(net), sort) # in make_sortref
    if isnothing(id2) # Did not find existing ...
        if isnothing(sortid) # and no enclosing provided name/id ...
            sortid = gensym(seed) # so invent one.
        end
    end
    # fill_sort_tag! will not overwrite existing, returns AbstractSortRef
    return fill_sort_tag!(net, sortid, sort, dict)::AbstractSortRef # in make_sortref
end

end # module Sorts

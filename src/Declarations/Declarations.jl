module Declarations

export AbstractDeclaration
export      SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
export      OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
export      VariableDeclaration
export      UnknownDeclaration

export element_ids, verify_partition

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage

using PNML
using PNML: DeclDict
using PNML: REFID, AnyElement, AbstractTerm
using PNML: arbitrarysorts, partitionsorts, partitionops
using PNML: namedoperators, arbitraryops, feconstants
using PNML: multisetsorts

# Extend PNML core #TODO what interfaces?
import PNML: sortof, sortref, sortdefinition, sortelements, basis # Sort related
import PNML: name # Lots has human-readable name strings.
import PNML: pid, refid # PNML ID
import PNML: fill_sort_tag!

using ..Sorts
using ..IDRegistrys

include("declarations.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

# # These 3 are Declarations of sorts, not AbstractSorts!
fill_sort_tag!(ctx, tag, sort::NamedSort) = fill_sort_tag!(ctx, tag, sort, PNML.namedsorts)::AbstractSortRef
fill_sort_tag!(ctx, tag, sort::PartitionSort) = fill_sort_tag!(ctx, tag, sort, PNML.partitionsorts)::AbstractSortRef
fill_sort_tag!(ctx, tag, sort::ArbitrarySort) = fill_sort_tag!(ctx, tag, sort, PNML.arbitrarysorts)::AbstractSortRef

end # module Declarations

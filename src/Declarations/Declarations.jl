module Declarations

export AbstractDeclaration
export      SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
export      OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
export      VariableDeclaration
export      UnknownDeclaration

export element_ids

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using Logging, LoggingExtras

using PNML
using PNML: DeclDict
using PNML: REFID, AnyElement, AbstractTerm, UserOperator, UserSort
using PNML: arbitrarysorts, partitionsorts, partitionops
using PNML: namedoperators, arbitraryops, feconstants

# Extend PNML core #TODO what interfaces?
import PNML: sortof, sortref, sortdefinition, sortelements, basis # Sort related
import PNML: name # Lots has human-readable name strings.
import PNML: pid, refid # PNML ID
import ..Expressions: toexpr

using ..Sorts
using ..PnmlIDRegistrys

include("declarations.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations

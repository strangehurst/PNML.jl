module Declarations

export AbstractDeclaration
export      SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
export      OperatorDeclaration, NamedOperator, ArbitraryOperator, FEConstant, PartitionElement
export      VariableDeclaration
export      UnknownDeclaration

export element_ids

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using TermInterface
using Logging, LoggingExtras

using PNML
# Extend PNML core #TODO what interfaces?
import PNML: sortof, sortref, sortdefinition, sortelements, basis # Sort related
import PNML: name # Lots has human-readable name strings.
import PNML: pid, refid # PNML ID
import PNML: toexpr # expressions

using PNML: REFID, AnyElement, AbstractTerm, UserOperator, UserSort
using PNML: arbitrarysorts, partitionsorts, partitionops
using PNML: namedoperators, arbitraryops, feconstants

using ..Sorts
using ..PnmlIDRegistrys

include("declarations.jl")
include("feconstants.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations

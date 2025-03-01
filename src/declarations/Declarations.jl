module Declarations

export AbstractDeclaration, UnknownDeclaration,
        SortDeclaration, OperatorDeclaration, VariableDeclaration,
        NamedSort, NamedOperator,
        ArbitrarySort, ArbitraryOperator,
        FEConstant, PartitionElement, PartitionSort,
        gtp_impl, peo_impl, refid, element_ids

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using TermInterface
using Logging, LoggingExtras

using PNML
import PNML: sortof, sortref, sortdefinition, sortelements, basis, tag, pid, refid, name, REFID
import PNML: toexpr
using PNML: AnyElement, AbstractTerm, indent, inc_indent, UserOperator, UserSort

using PNML: place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset
using PNML: variabledecls,
    usersorts, namedsorts, arbitrarysorts, partitionsorts, partitionops,
    namedoperators, arbitraryops, feconstants, SubstitutionDict

using ..Sorts
using ..PnmlIDRegistrys

include("declarations.jl")
include("feconstants.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations

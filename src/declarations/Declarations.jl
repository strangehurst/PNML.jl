module Declarations

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using TermInterface

using PNML
import PNML: sortof, sortelements, basis, tag, pid, name
using PNML: AnyElement, AbstractTerm, indent, inc_indent, UserOperator

using PNML: page_idset, place_idset, transition_idset, arc_idset,
    refplace_idset, reftransition_idset
using PNML: variabledecls,
    usersorts, namedsorts, arbitrarysorts, partitionsorts, partitionops,
    namedoperators, arbitrary_ops, feconstants

using ..Sorts
using ..PnmlIDRegistrys

include("declarations.jl")
include("partitions.jl")
include("feconstants.jl")
include("arbitrarydeclarations.jl")

# NB: `Declaration` is a label.
export AbstractDeclaration, UnknownDeclaration,
        SortDeclaration, OperatorDeclaration, VariableDeclaration,
        NamedSort, NamedOperator,
        ArbitrarySort, ArbitraryOperator,
        FEConstant, PartitionElement, PartitionSort

end # module Declarations

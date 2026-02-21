module Declarations

export AbstractDeclaration
export      SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
export      OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
export      VariableDeclaration, UnknownDeclaration

export element_ids, verify_partition

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage

using PNML
using PNML: REFID, AnyElement, AbstractTerm
using PNML: arbitrarysorts, partitionsorts, partitionops
using PNML: namedoperators, arbitraryops, feconstants, multisetsorts
using PNML: namedsort, arbitrarysort, partitionsort, partitionop
using PNML: arbitraryop, feconstant, multisetsort
using PNML: isusersort, isnamedsort, ispartitionsort, isproductsort
using PNML: ismultisetsort, isarbitrarysort, indent, inc_indent
using PNML: PnmlException, MissingIDException, DuplicateIDException, MalformedException

import PNML: sortof, sortref, sortdefinition, sortelements, basis # Sort related
import PNML: name # Many things have human-readable name strings.
import PNML: pid, refid # PNML ID
import PNML: fill_sort_tag!, verify!

using ..Sorts
using ..Sorts: equalSorts
using ..IDRegistrys

include("declarations.jl")
include("partitions.jl")
include("arbitrarydeclarations.jl")

end # module Declarations

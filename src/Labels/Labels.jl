module Labels

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage

import Base: eltype
import AutoHashEquals: @auto_hash_equals
import Multisets
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet

using PNML
using PNML: Maybe, nettype, AnyElement
using PNML: AbstractLabel, Annotation, HLAnnotation
using PNML: DeclDict, DictType
using PNML: PnmlMultiset, AbstractTerm
using PNML: namedsort, namedsorts, multisetsorts, multisetsorts
using PNML: labelof, ToolParser, LabelParser, ParseContext

import PNML: name
import PNML: value_type
import PNML: value, term,  graphics, toolinfos, refid, tag, elements
import PNML: has_graphics, get_label, has_label, has_labels, labels, declarations, decldict

using ..PnmlTypes # PNML PNTD

import ..Expressions: toexpr, PnmlExpr


using ..Sorts
# Some labels implement the Sort interface
import PNML: basis, sortref, sortof, sortelements, sortdefinition, version

include("toolinfos.jl") # labels and nodes can both have tool specific information

include("PnmlGraphics.jl") # labels and nodes can both have graphics
using .PnmlGraphics

"""
    default(::Type{T<:AbstractLabel}, pntd::PnmlType; ddict::DeclDict) -> T

Return a default label `T` for `pntd`.
"""
function default end


include("labels.jl")
include("declaration.jl")
include("name.jl")
include("sorttype.jl")
include("inscriptions.jl")
include("markings.jl")
include("conditions.jl")
include("rates.jl")
include("structure.jl")

export Inscription, Marking, Condition
export Name, PnmlLabel, SortType, Declaration
export HLLabel
export Graphics, PnmlGraphics
export ToolInfo
export text, get_label, rate_value, delay_value
export def_sort_element
export ToolParser

export Rate
export default

end # module labels

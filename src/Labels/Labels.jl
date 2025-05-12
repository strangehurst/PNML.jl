module Labels
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
using NamedTupleTools
import Multisets
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
using Logging, LoggingExtras

using PNML
using PNML: Maybe, nettype, AnyElement
using PNML: DeclDict, DictType
using PNML: PnmlMultiset, AbstractTerm
using PNML: usersort, namedsort
using PNML: labelof

import PNML: name
import PNML: value, term,  graphics, tools, refid, tag, elements
import PNML: has_graphics, get_label, has_label, has_labels, labels, declarations

import ..Expressions: toexpr, PnmlExpr

using ..PnmlTypeDefs # PNML PNTD

using ..Sorts
# Some labels implement the Sort interface
import PNML: basis, sortref, sortof, sortelements, sortdefinition

include("toolinfos.jl") # labels and nodes can both have tool specific information

include("PnmlGraphics.jl") # labels and nodes can both have graphics
using .PnmlGraphics

include("labels.jl")
include("name.jl")
include("sorttype.jl")
include("inscriptions.jl")
include("markings.jl")
include("conditions.jl")
include("rates.jl")
include("structure.jl")

export AbstractLabel, Condition, Declaration, Inscription, Marking
export Name, PnmlLabel, SortType
export HLAnnotation, HLInscription, HLMarking, HLLabel
export Graphics, PnmlGraphics
export ToolInfo
export text, get_label, rate_value, delay_value
export def_sort_element
export ToolParser

export Rate

end # module labels

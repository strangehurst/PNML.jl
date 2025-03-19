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
using PNML: Maybe, nettype, AnyElement, Graphics, ToolInfo, number_value, REFID
using PNML: indent, inc_indent
using PNML: DeclDict, DictType, XDVT, XDVT2
using PNML: PnmlMultiset, pnmlmultiset, BooleanConstant, NumberConstant, AbstractTerm
using PNML: namedsort

import PNML: usersort, sortdefinition, def_sort_element
import PNML: sortof, sortref, sortelements, basis, value,term,  graphics, tools, refid, tag, elements
import PNML: has_graphics, get_label, has_label, has_labels, labels, declarations
import PNML: toexpr, PnmlExpr, PnmlTupleEx
import PNML: variables
import PNML: decldict

using ..PnmlTypeDefs
using ..Sorts

include("labels.jl")
include("name.jl")
include("sorttype.jl")
include("inscriptions.jl")
include("markings.jl")
include("conditions.jl")
include("rates.jl")
include("structure.jl")

export AbstractLabel, Condition, Declaration, Inscription, Marking
export Name, PnmlLabel, SortType, TransitionRate
export HLAnnotation, HLInscription, HLMarking, HLLabel

export text, get_labels, get_label, rate, delay

end # module labels

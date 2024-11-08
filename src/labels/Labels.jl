module Labels
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
import Multisets

using PNML
using PNML: Maybe, nettype, AnyElement, Graphics, ToolInfo, number_value, REFID
using PNML: indent, inc_indent
using PNML: DeclDict, DictType, XDVT, XDVT2
using PNML: PnmlMultiset, pnmlmultiset, BooleanConstant, NumberConstant, AbstractTerm
using PNML: namedsort

import PNML: usersort, sortdefinition, def_sort_element
import PNML: sortof, sortref, sortelements, basis, value, graphics, tools, refid, tag, elements
import PNML: has_graphics, get_label, has_label, has_labels, labels, declarations
import PNML: place_type, transition_type, arc_type, refplace_type, reftransition_type
import PNML: marking_type, inscription_type, condition_type, coordinate_type
import PNML: marking_value_type, inscription_value_type, condition_value_type, coordinate_value_type
import PNML: rate_value_type
import PNML: toexpr

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

export AbstractLabel, Name, Marking, HLMarking, Condition, Inscription, HLInscription,
       Declaration, SortType, PnmlLabel, TransitionRate,
       default_typeusersort,
       text, sorttag, get_labels, get_label, decldict, rate, delay,
       default_inscription, default_hlinscription, default_condition,
       default_marking, default_hlmarking, default_typeusersort

end # module labels

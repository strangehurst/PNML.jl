module Labels
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import AutoHashEquals: @auto_hash_equals
using DocStringExtensions
import Multisets

using PNML
using PNML: Maybe, nettype, AnyElement, Graphics, ToolInfo, number_value,
    XDVT, XDVT2, indent, inc_indent,
    DeclDict, DictType,
    PnmlMultiset, pnmlmultiset,
    BooleanConstant, NumberConstant,
    AbstractTerm
using PNML: namedsort

import PNML: sortof, sortelements, basis, value, _evaluate, graphics, tools, tag, elements,
    has_graphics, get_label, has_label, has_labels, labels, declarations
import PNML:
    place_type, transition_type, arc_type, refplace_type, reftransition_type,
    marking_type, inscription_type, condition_type,
    marking_value_type, inscription_value_type, condition_value_type,
    rate_value_type,
    coordinate_type, coordinate_value_type

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

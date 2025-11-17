module Labels

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using Logging, LoggingExtras
using SciMLLogging: @SciMLMessage
using Moshi.Data: @data, isa_variant, is_data_type

import Base: eltype
import AutoHashEquals: @auto_hash_equals
import Multisets
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet

using PNML
using PNML: Maybe, nettype, AnyElement, D
using PNML: AbstractPnmlNode, AbstractLabel, Annotation, HLAnnotation
using PNML: DeclDict, DictType
using PNML: PnmlMultiset, AbstractTerm
using PNML: namedsort, namedsorts, multisetsorts, multisetsorts
using PNML: labelof, ToolParser, LabelParser, ParseContext

import PNML: name
import PNML: value_type
import PNML: value, term, graphics, toolinfos, refid, tag, elements
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
include("arctypes.jl")
include("rates.jl")
include("delays.jl")
include("priorities.jl")
include("structure.jl")

"""
    label_value(n::AbstractPnmlNode, tag::Symbol, type) -> x::type

If there is a label `tag` in `n.extralabels`, return its value,
else return a default vale of the correct Type.
"""
function label_value(n::AbstractPnmlNode, tag::Symbol, type, default)
    label = labelof(n, tag)
    if isnothing(label)
        default(type)
    else
        @show label
        value(label)::type
    end
end

# "Parse content of `<text>` as a number of `value_type`."
# function number_content_parser(label, value_type)
#     #@show label value_type #! debug
#     str = PNML.text_content(elements(label)) #! xmldict format
#     PNML.number_value(value_type, str)::Number
#  end

export Inscription, Marking, Condition
export Name, PnmlLabel, SortType, Declaration
export HLLabel
export Graphics, PnmlGraphics
export ToolInfo
export text, get_label, label_value, rate_value, priority_value, delay_value
export def_sort_element
export ToolParser
export ArcType, ArcT
export Rate, Priority
export default

end # module labels

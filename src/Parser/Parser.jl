"""
Parser module of PNML.

See [`LabelParser`](@ref), (`ToolParser`)(@ref).
"""
module Parser
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import EzXML
import XMLDict
import Multisets: Multisets, Multiset

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using TermInterface
using Logging, LoggingExtras
using Moshi.Data: @data, isa_variant, is_data_type
using Moshi.Match: @match
using SciMLLogging: @SciMLMessage
using SciMLPublic: @public

using PNML
using ..Expressions
using ..IDRegistrys
using ..PnmlTypes
using ..Labels
using ..Sorts
using ..Sorts: make_sortref
using ..Declarations

using PNML: Maybe, CONFIG, AnyElement, PnmlLabel, D
using PNML: Graphics, Coordinate
using PNML: ToolInfo, DictType
using PNML: DeclDict, PnmlNetData, PnmlNetKeys
using PNML: PartitionElement, PnmlMultiset
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator
using PNML: Context
using PNML: pid
using PNML: multisetsorts
using PNML: ParseContext, parser_context, ToolParser, LabelParser
using PNML: default, fill_sort_tag!
using PNML: namedsort, multisetsort, productsort
using PNML: namedsorts, multisetsorts, productsorts
using PNML: partitionsort, partitionsorts
using PNML: pagedict, placedict, transitiondict, arcdict, refplacedict, reftransitiondict
using PNML: page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset
using PNML: netsets, toolinfos
using PNML: NamedSortRef, PartitionSortRef, ProductSortRef, MultisetSortRef, ArbitrarySortRef

# Methods implemented in this module.
import PNML: adjacent_place
import PNML: basis, sortref, sortof, sortelements, sortdefinition
import PNML: refid, netdata, tag, verify!

include("xmlutils.jl")
include("parseutils.jl")
include("anyelement.jl")
include("model.jl")
include("nodes.jl")
include("labels.jl")
include("graphics.jl")
include("declarations.jl")
include("terms.jl")
include("toolspecific.jl")

export XMLNode, xmlnode, @xml_str
export pnmlmodel
@public to_sort

end

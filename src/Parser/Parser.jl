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
using Moshi.Match: @match
using SciMLLogging: @SciMLMessage
using SciMLPublic: @public

using PNML
using ..Expressions
using ..PnmlIDRegistrys
using ..PnmlTypes
using ..Labels
using ..Sorts
using ..Sorts: make_sortref
using ..Declarations

using PNML: Maybe, CONFIG, AnyElement
using PNML: Graphics, Coordinate
using PNML: ToolInfo, DictType
using PNML: DeclDict, PnmlNetData, PnmlNetKeys
using PNML: PartitionElement, PnmlMultiset
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator
using PNML: UserSort
using PNML: Context
using PNML: usersort, usersorts, pid
using PNML: multisetsorts
using PNML: ParseContext, parser_context, ToolParser, LabelParser
using PNML: inscription_type, marking_type, transition_type
using PNML: default, fill_sort_tag!
using PNML: usersort, namedsort, usersorts, namedsorts, multisetsorts, multisetsorts
using PNML: partitionsort, partitionsorts
using PNML: pagedict, placedict, transitiondict, arcdict, refplacedict, reftransitiondict
using PNML: page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset
using PNML: netsets, toolinfos

# Methods implemented in this module.
import PNML: adjacent_place
import PNML: basis, sortref, sortof, sortelements, sortdefinition
import PNML: refid, netdata

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

export XMLNode, xmlroot, @xml_str
export pnmlmodel

@public deduce_sort

end

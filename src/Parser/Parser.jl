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

using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using TermInterface
using Logging, LoggingExtras

using PNML
using ..Expressions
using ..PnmlIDRegistrys
using ..PnmlTypes
using ..Labels
using ..Sorts
using ..Declarations

using PNML: Maybe, CONFIG, AnyElement
using PNML: Graphics, Coordinate
using PNML: ToolInfo, DictType
using PNML: DeclDict, PnmlNetData, PnmlNetKeys
using PNML: PartitionElement, PnmlMultiset
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator
using PNML: Context
using PNML: usersort, usersorts, pid
using PNML: ParseContext, parser_context, ToolParser, LabelParser
using PNML: inscription_type, marking_type, transition_type
using PNML: default

# Methods implemented in this module.
import PNML: adjacent_place
import PNML: basis, sortref, sortof, sortelements, sortdefinition

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

public deduce_sort

end

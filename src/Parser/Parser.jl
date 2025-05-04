"""
Parser module of PNML.

See [`LabelParser`](@ref), (`Labels.ToolParser`)(@ref).
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

# Methods implemented in this module.
import PNML: adjacent_place

using PNML: Maybe, CONFIG, DECLDICT, idregistry, AnyElement
using PNML: Graphics, Coordinate
using PNML: ToolInfo, DictType
using PNML: DeclDict, PnmlNetData, PnmlNetKeys
using PNML: PartitionElement, PnmlMultiset
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator

using PNML: usersort, sortof, basis, pid
import PNML: basis, sortref, sortof, sortelements, sortdefinition

using ..Expressions
using ..PnmlIDRegistrys
using ..PnmlTypeDefs
using ..Labels
using ..Labels: ToolParser
using ..Sorts
using ..Declarations

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

public deduce_sort, LabelParser

end

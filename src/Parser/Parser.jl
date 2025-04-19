"""
    Parser module of PNML
"""
module Parser
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import EzXML
import XMLDict
using DocStringExtensions
using NamedTupleTools
import Multisets: Multisets, Multiset
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
import ..Sorts: basis, sortref, sortof, sortelements, sortdefinition
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator

using PNML: usersort, sortof, basis, pid

using ..Expressions
using ..PnmlIDRegistrys
using ..PnmlTypeDefs
using ..Labels
using ..Sorts
using ..Declarations

include("xmlutils.jl")
include("parseutils.jl")
include("anyelement.jl")
include("parse.jl")
include("graphics.jl")
include("declarations.jl")
include("terms.jl")
include("toolspecific.jl")

export XMLNode, xmlroot, @xml_str
export parse_str, parse_pnml, parse_file
export parse_net, parse_page!
export parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition
export parse_name, parse_text
export parse_inscription, parse_initialMarking
export parse_hlinscription, parse_hlinitialMarking, parse_condition
export parse_graphics, parse_graphics_coordinate
export parse_tokengraphics, parse_tokenposition
export parse_declaration, parse_sort, parse_term
export parse_namedsort, parse_namedoperator
export parse_unknowndecl, parse_variabledecl, parse_feconstants
export parse_excluded, parse_structure
public deduce_sort

end

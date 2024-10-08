module Parser
import OrderedCollections: OrderedDict, LittleDict, freeze
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import AutoHashEquals: @auto_hash_equals
import EzXML
import XMLDict
#using Reexport
using DocStringExtensions
import Multisets: Multisets, Multiset
using TermInterface
using PNML
import PNML: elements, sortelements, sortof, basis, value, tag, pid

using PNML: Maybe, CONFIG, DECLDICT, idregistry, AnyElement, number_value,
    Graphics, Coordinate, TokenGraphics,
    ToolInfo, DictType,
    XDVT, XDVT2, indent, inc_indent,
    DeclDict, PnmlNetData, PnmlNetKeys, tunesize!, fill_nonhl!,
    PartitionElement,
    PnmlMultiset, pnmlmultiset,
    BooleanConstant, NumberConstant,
    AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator,
    isoperator, isbooleanoperator, isintegeroperator, ismultisetoperator,
    isfiniteoperator, ispartitionoperator, isbuiltinoperator,
    isvariable,
    pnml_hl_operator, pnml_hl_outsort
using PNML: page_idset, place_idset, transition_idset, arc_idset,
    refplace_idset, reftransition_idset
using PNML: variabledecls, usersort,
    usersorts, namedsorts, arbitrarysorts, partitionsorts, partitionops,
    useroperators, namedoperators, arbitraryops, feconstants
using PNML:
    page_type, place_type, transition_type, arc_type, refplace_type, reftransition_type,
    marking_type, inscription_type, condition_type,
    marking_value_type, inscription_value_type, condition_value_type,
    rate_value_type,
    coordinate_type, coordinate_value_type,
    validate_declarations

using ..PnmlIDRegistrys
using ..PnmlTypeDefs
using ..Labels
using ..Sorts
using ..PnmlGraphics
using ..Declarations

include("xmlutils.jl")
include("parseutils.jl")
include("anyelement.jl")
include("parse.jl")
include("graphics.jl")
include("declarations.jl")
include("terms.jl")
include("toolspecific.jl")

"""
    registry() -> PnmlIDRegistry

Construct an empty PNML ID registry using a ReentrantLock.
"""
function registry()
    PnmlIDRegistry()
end

export XMLNode, xmlroot, @xml_str, parse_str, parse_pnml, parse_file,
    unparsed_tag,
    parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_condition,
    parse_inscription, parse_hlinscription,
    parse_initialMarking, parse_hlinitialMarking,
    parse_graphics, parse_graphics_coordinate, parse_tokengraphics, parse_tokenposition,
    parse_declaration,
    parse_namedsort, parse_namedoperator, parse_variable, parse_sort,
    parse_unknowndecl, parse_term, parse_feconstants, parse_variabledecl,
    parse_excluded, parse_structure,
    registry

end

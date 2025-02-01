module Parser
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import EzXML
import XMLDict
#using Reexport
using DocStringExtensions
using NamedTupleTools
import Multisets: Multisets, Multiset
using TermInterface
using PNML
import PNML: elements, sortelements, sortof, basis, value, term, tag, pid, refid, toexpr
import PNML: adjacent_place, page_pnk, place_pnk, arc_pnk, transition_pnk, refplace_pnk, reftransition_pnk
#import InteractiveUtils

using PNML: Maybe, CONFIG, DECLDICT, REFID, idregistry, AnyElement, number_value,
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
    pnml_hl_operator, pnml_hl_outsort
using PNML: page_idset, place_idset, transition_idset, arc_idset,
    refplace_idset, reftransition_idset
using PNML: has_variabledecl, has_namedsort, has_arbitrarysort, has_partitionsort, has_namedop,
    has_arbitraryop, has_partitionop, has_feconstant, has_usersort, has_useroperator,
    usersorts, useroperators, variabledecls, namedsorts,
    arbitrarysorts, partitionsorts, namedoperators, arbitraryops, partitionops, feconstants,
    variable, namedsort, arbitrarysort, partitionsort,
    namedop, arbitrary_op, partitionop, feconstant, usersort, useroperator
using PNML: fill_sort_tag!
using PNML:
    page_type, place_type, transition_type, arc_type, refplace_type, reftransition_type,
    marking_type, inscription_type, condition_type,
    marking_value_type, inscription_value_type, condition_value_type,
    rate_value_type,
    coordinate_type, coordinate_value_type,
    validate_declarations,
    def_sort_element
using PNML:  toexpr, VariableEx, UserOperatorEx, NumberEx, BooleanEx, PnmlTupleEx,
    Bag, Add, Subtract, ScalarProduct, Cardinality, CardinalityOf, Contains, Or,
    And, Not, Imply, Equality, Inequality, Successor, Predecessor,
    PartitionElementOp, PartitionLessThan, PartitionGreaterThan, PartitionElementOf,
    Addition, Subtraction, Multiplication, Division,
    GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual, Modulo,
    Concatenation, Append, StringLength, Substring,
    StringLessThan, StringLessThanOrEqual, StringGreaterThan, StringGreaterThanOrEqual,
    ListLength, ListConcatenation, Sublist, ListAppend, MemberAtIndex

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
    r = PnmlIDRegistry()
    #println("create PnmlIDRegistry ", objectid(r)) #! debug
    return r
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
    parse_namedsort, parse_namedoperator, parse_sort,
    parse_unknowndecl, parse_term, parse_feconstants, parse_variabledecl,
    parse_excluded, parse_structure,
    registry,
    unwrap_subterm

end

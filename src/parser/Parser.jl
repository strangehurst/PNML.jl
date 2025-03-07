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
using Logging, LoggingExtras

using PNML
import PNML: elements, sortelements, sortof, basis, value, term, tag, pid, refid, toexpr
import PNML: adjacent_place, page_pnk, place_pnk, arc_pnk, transition_pnk, refplace_pnk, reftransition_pnk
#import InteractiveUtils

using PNML: Maybe, CONFIG, DECLDICT, REFID, idregistry, AnyElement, number_value
using PNML: Graphics, Coordinate, TokenGraphics
using PNML: ToolInfo, DictType
using PNML: XDVT, XDVT2, indent, inc_indent
using PNML: DeclDict, PnmlNetData, PnmlNetKeys, tunesize!, fill_nonhl!
using PNML: PartitionElement,PnmlMultiset, pnmlmultiset, BooleanConstant, NumberConstant
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator
using PNML: isoperator, isbooleanoperator, isintegeroperator, ismultisetoperator
using PNML: page_idset, place_idset, transition_idset, arc_idset
using PNML: refplace_idset, reftransition_idset
using PNML: has_partitionsort
using PNML: has_partitionop, has_feconstant
using PNML: usersorts, useroperators, variabledecls, namedsorts
using PNML: arbitrarysorts, partitionsorts, namedoperators, arbitraryops, partitionops, feconstants
using PNML: variable, namedsort, arbitrarysort, partitionsort
using PNML: namedop, arbitrary_op, partitionop, feconstant, usersort, useroperator
using PNML: fill_sort_tag!

using PNML: page_type, place_type, transition_type, arc_type, refplace_type, reftransition_type
using PNML: marking_type, inscription_type, condition_type
using PNML: marking_value_type, inscription_value_type, condition_value_type
using PNML: rate_value_type
using PNML: coordinate_type, coordinate_value_type
using PNML: validate_declarations, validate_toolinfos
using PNML: def_sort_element
using PNML: toexpr, VariableEx, UserOperatorEx, NumberEx, BooleanEx, PnmlTupleEx
using PNML: Bag, Add, Subtract, ScalarProduct, Cardinality, CardinalityOf, Contains, Or
using PNML: And, Not, Imply, Equality, Inequality, Successor, Predecessor
using PNML: PartitionElementOp, PartitionLessThan, PartitionGreaterThan, PartitionElementOf
using PNML: Addition, Subtraction, Multiplication, Division
using PNML: GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual, Modulo
using PNML: Concatenation, Append, StringLength, Substring
using PNML: StringLessThan, StringLessThanOrEqual, StringGreaterThan, StringGreaterThanOrEqual
using PNML: ListLength, ListConcatenation, Sublist, ListAppend, MemberAtIndex

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

# global_logger(PNML.pnml_logger[])
# @info "parser logger $(current_logger())"

"""
    registry() -> PnmlIDRegistry

Construct an empty PNML ID registry using a ReentrantLock.
"""
function registry()
    r = PnmlIDRegistry()
    #println("create PnmlIDRegistry ", objectid(r)) #! debug
    return r
end

export XMLNode, xmlroot, @xml_str, parse_str, parse_pnml, parse_file, unparsed_tag,
    parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_condition,
    parse_inscription, parse_hlinscription, parse_initialMarking, parse_hlinitialMarking,
    parse_graphics, parse_graphics_coordinate, parse_tokengraphics, parse_tokenposition,
    parse_declaration, parse_namedsort, parse_namedoperator, parse_sort,
    parse_unknowndecl, parse_term, parse_feconstants, parse_variabledecl,
    parse_excluded, parse_structure, registry, unwrap_subterm, deduce_sort

end

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
import PNML: elements, sortelements, sortof, basis, value, term, tag, pid, refid, toexpr
import PNML: adjacent_place
#import PNML: page_idset, place_idset, arc_idset, transition_idset, refplace_idset, reftransition_idset

using PNML: Maybe, CONFIG, DECLDICT, idregistry, AnyElement
using PNML: Graphics, Coordinate, TokenGraphics
using PNML: ToolInfo, DictType
using PNML: DeclDict, PnmlNetData, PnmlNetKeys
using PNML: PartitionElement,PnmlMultiset, BooleanConstant, NumberConstant
using PNML: AbstractTerm, AbstractOperator, AbstractVariable, UserOperator, Operator
using PNML: isoperator, isbooleanoperator, isintegeroperator, ismultisetoperator

using PNML: def_sort_element

using PNML: usersorts, useroperators, namedsorts
using PNML: arbitrarysorts, partitionsorts, namedoperators, arbitraryops, partitionops, feconstants
using PNML: variable, namedsort, arbitrarysort, partitionsort
using PNML: namedop, arbitraryop, partitionop, feconstant, usersort, useroperator

using PNML: validate_declarations, validate_toolinfos

# Expressions
using PNML: toexpr, PnmlExpr, VariableEx, UserOperatorEx, PnmlTupleEx
using PNML: Bag, Add, Subtract, ScalarProduct, Cardinality, CardinalityOf, Contains, Or
using PNML: And, Not, Imply, Equality, Inequality, Successor, Predecessor
using PNML: PartitionLessThan, PartitionGreaterThan, PartitionElementOf
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

export XMLNode, xmlroot, @xml_str, parse_str, parse_pnml, parse_file, unparsed_tag
export parse_net, parse_page!
export parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition
export parse_name, parse_text
export parse_inscription, parse_initialMarking
export parse_condition, parse_hlinscription, parse_hlinitialMarking
export parse_graphics, parse_graphics_coordinate, parse_tokengraphics, parse_tokenposition
export parse_declaration, parse_sort, parse_term, parse_namedsort, parse_namedoperator
export parse_unknowndecl, parse_feconstants, parse_variabledecl
export parse_excluded, parse_structure
public deduce_sort

end

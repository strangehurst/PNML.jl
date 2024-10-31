"""
[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, LabelledArrays, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.

What is accepted as values is ~~often~~ a supartitionsperset of what a given pntd schema specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

The pnml specification has layers. This package has layers: `PnmlNet`, `AbstractPetriNet`

The core layer is useful and extendable. The standard defines extensions of the core,
called meta-models, for
  - place-transition petri nets (integers) and
  - high-level petri net graphs (many-sorted algebra).
This package family adds non-standard continuous net (float64) support.
Note that there is not yet any RelaxNG schema for our extensions.

On top of the concrete `PnmlNet` of the IR are net adaptions and interpertations.
This is the level that Petri Net conformance can be imposed.
It is also where other Net constructs can be defined over `PnmlNet`s. Perhaps as new meta-models.
"""
module PNML

# CONFIG structure copied from Tim Holy's Cthulhu.jl.
"""
Configuration with default values that can be overidden by a LocalPreferences.toml.
# Options
  - `indent_width::Int`: Indention of nested lines.
  - `text_element_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
  - `warn_on_fixup::Bool`: When an missing value is replaced by a default value, issue a warning.
  - `warn_on_namespace::Bool`: There are pnml files that break the rules & do not have an xml namespace.
  - `warn_on_unclaimed::Bool`: Issue warning when PNML label does not have a parser defined. While allowed, there will be code required to do anything useful with the label.
  - `warn_on_unimplemented::Bool`: Issue warning to highlight something unimplemented. Expect high volume of messages.
  - `verbose::Bool`: Print information as runs.
"""
Base.@kwdef mutable struct PnmlConfig
    indent_width::Int           = 4
    text_element_optional::Bool = true
    verbose::Bool           = false
    warn_on_fixup::Bool     = false
    warn_on_namespace::Bool = true
    warn_on_unclaimed::Bool = false
    warn_on_unimplemented::Bool = false
end

using Base.ScopedValues

"See [`PnmlConfig`](@ref) for default values."
const CONFIG = ScopedValue(PnmlConfig()) # = PnmlConfig()
include("preferences.jl")

__init__() = read_config!(CONFIG[])


# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

import AutoHashEquals: @auto_hash_equals
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import Base: (*), (+), (-)
import FunctionWrappers
import Reexport: @reexport
import DecFP
import Graphs
import MetaGraphsNext
import OrderedCollections: OrderedDict, LittleDict, freeze
import EzXML
import XMLDict
using TermInterface
using Metatheory
import Multisets: Multisets, Multiset
#~import StyledStrings
Multisets.set_key_value_show()

using LabelledArrays #Todo beware namespace pollution
using NamedTupleTools
using DocStringExtensions
using Compat: @compat

#export @xml_str, xmlroot
#export parse_str, parse_file, parse_pnml
export PnmlModel, PnmlNet, Page, Place, RefPlace, Transition, RefTransition, Arc
export declarations, pid, refid, sortof, sortref, basis

export has_variable, has_namedsort, has_arbitrarysort, has_partitionsort, has_namedop,
    has_arbitraryop, has_partitionop, has_feconstant, has_usersort, has_useroperator,
    usersorts, useroperators, variabledecls, namedsorts,
    arbitrarysorts, partitionsorts, namedoperators, arbitraryops, partitionops, feconstants,
    variable, namedsort, arbitrarysort, partitionsort,
    namedop, arbitrary_op, partitionop, feconstant, usersort, useroperator

export DeclDict, UserOperator, NamedOperator, UserSort, NamedSort, sortdefinition
export PnmlException, MissingIDException, MalformedException

export Variable

export place_idset, transition_function, initial_markings, rates

export placedict, transitiondict, arcdict, refplacedict, reftransitiondict
export nplaces, ntransitions, narcs, nrefplaces, nreftransitions

export page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset

export variabledecls,
    usersorts,  namedsorts, arbitrarysorts, partitionsorts, partitionops,
    useroperators, namedoperators, arbitraryops,
    feconstants,
    usersort, namedsort, feconstant

export toexpr, PnmlExpr, BoolExpr, VariableEx, UserOperatorEx,
    Bag, Add, Subtract, ScalarProduct, Cardinality, CardinalityOf, Contains, Or,
    And, Not, Imply, Equality, Inequality, Successor, Predecessor,
    PartitionElementOp, PartitionLessThan, PartitionGreaterThan, PartitionElementOf,
    Addition, Subtraction, Multiplication, Division,
    GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual, Modulo,
    Concatenation, Append, StringLength, Substring,
    StringLessThan, StringLessThanOrEqual, StringGreaterThan, StringGreaterThanOrEqual,
    ListLength, ListConcatenation, Sublist, ListAppend, MemberAtIndex

include("PnmlTypeDefs.jl")
using .PnmlTypeDefs

include("PnmlIDRegistrys.jl")
using .PnmlIDRegistrys

"ID registry of the current scope. Nets are the usual scope = a net-level-global."
const idregistry = ScopedValue{PnmlIDRegistry}() # undefined until PnmlModel created

include("Core/exceptions.jl")
include("Core/utils.jl")

include("Core/interfaces.jl") # Function docstrings mostly.
include("Core/types.jl") # Abstract Types with docstrings.
include("Core/anyelement.jl") # AnyElement, DictType

include("Core/decldictcore.jl") # define things used by Sorts, Declarations

# Single per-net DeclDict
const DECLDICT = ScopedValue{DeclDict}() # undefined until PnmlModel created

# Parts of Labels and Nodes.

include("sorts/Sorts.jl") # used in Variables, Operators, Places
using .Sorts

include("terms/multisets.jl") # uses UserSort declaration
include("terms/constterm.jl") #
include("terms/booleans.jl")
include("terms/variables.jl") #~ Work in progress

include("terms/expressions.jl") # Bag
include("terms/operators.jl")

include("terms/terms.jl") # Variables and AbstractOperators preceed this.
include("terms/tuples.jl") #~ Work in progress
include("Core/rewrite.jl")

# 2024-07-22 moved forward, holds Any rather than node types.
include("Core/pnmlnetdata.jl") # Used by page, net; holds places, transitions, arcs.

include("declarations/Declarations.jl")
using .Declarations
import .Declarations: NamedSort
using .Declarations: sortdefinition

# Declarations are inside a <declaration> Label.
# NamedSort declaration wraps (ID, name, <:AbstractSort).
# UserSort is not a declaration, but a sort that refers to a declaration by REFID.

#^ Above here are things that appear in  DeclDict contents.
#^ 2024-07-17 Changed DeclDict to be Any based,
#^ with the hope that the accessors defined here provide type inferrability.
include("Core/decldict.jl") # Just show()

include("Core/graphics.jl") # labels and nodes can both have graphics
using .PnmlGraphics

include("Core/toolinfos.jl") # labels and nodes can both have tool specific information

# Labels
include("labels/Labels.jl")
using .Labels

# Nodes #TODO make into a module?
include("nodes/nodes.jl") # Concrete place, transition, arc.
include("nodes/page.jl") # Contains nodes.
include("nodes/net.jl") # The level of IDREGISTRY, DECLDICT. API for Petri nets, graphs work.
include("nodes/pagetree.jl") # AbstractTree used to print a PnmlNet.
include("nodes/model.jl") # Holds multiple PnmlNets.

include("Core/flatten.jl") # Apply to PnmlModel or PnmlNet #todo move to nodes?

# PARSE
include("parser/Parser.jl")
using .Parser

# API: Petri nets, metagraph
include("PNet/petrinet.jl")
include("PNet/transition_function.jl")
include("PNet/metagraph.jl")

include("precompile.jl")

end # module PNML

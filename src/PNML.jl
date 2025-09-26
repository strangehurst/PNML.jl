"""
[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.

What is accepted as values is ~~often~~ a superset of what a given pntd schema specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

The pnml standard has layers. This package has layers: `PnmlNet`, `AbstractPetriNet`

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
__precompile__(true)

include("preferences.jl") # PnmlConfig, read_config!, save_config, show

"See [`PnmlConfig`](@ref) for default values."
const CONFIG = Ref(PnmlConfig())

__init__() = read_config!(CONFIG[])


# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

import AutoHashEquals: @auto_hash_equals
import Base: eltype, keys, *, +, -, <, >,>=, <=, zero, length, iterate
import FunctionWrappers
import Reexport: @reexport
import Graphs
import MetaGraphsNext
import MacroTools
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import EzXML
import XMLDict
import Multisets: Multisets, Multiset
import Moshi.Match: @match
import Moshi.Data: @data
import SciMLPublic: @public
import Metatheory

using Logging
using LoggingExtras
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using TermInterface
using Graphs: SimpleDiGraphFromIterator, Edge
using MetaGraphsNext: MetaGraph
using NamedTupleTools
using DocStringExtensions

# EXPORTS

export PnmlModel, PnmlNet, Page, Place, RefPlace, Transition, RefTransition, Arc
export REFID, SortRef
export UserSortRef
export NamedSortRef, ProductSortRef, PartitionSortRef, MultisetSortRef, ArbitrarySortRef
export decldict
export @xml_str, xmlroot

@public pnmlmodel, pnmlnet
@public PnmlException, MissingIDException, DuplicateIDException, MalformedException
@public usersort, namedsort
@public labelof, transition_function, rates

Multisets.set_key_value_show()

include("logging.jl") # SciMLLogging based: `silent`, `verbose`, `logger_for_pnml`

include("PnmlTypes.jl")
using .PnmlTypes

include("PnmlIDRegistrys.jl")
using .PnmlIDRegistrys

include("Core/exceptions.jl")
include("Core/utils.jl")
include("Core/coordinates.jl")

include("context.jl")

include("Core/interfaces.jl") # Function docstrings mostly.
include("Core/anyelement.jl") # AnyElement, DictType, XDVT
include("Core/types.jl") # Abstract Types with docstrings.

include("Core/toolparser.jl")
include("Core/labelparser.jl")
include("Core/decldictcore.jl") # define structure filled by Sorts, Declarations

# Parts of Labels and Nodes.

include("terms/tuples.jl")

include("Core/parse_context.jl") # parse context has id registry and DeclDict

include("Sorts/Sorts.jl") # used in Variables, Operators, Places
using .Sorts
using .Sorts: MultisetSort
using .Sorts: AbstractSort, UserSort, MultisetSort, ProductSort
using .Sorts: DotSort, BoolSort, NumberSort, IntegerSort, PositiveSort, NaturalSort, RealSort
using .Sorts: EnumerationSort, CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort
using .Sorts: ListSort, StringSort


include("Declarations/Declarations.jl")
using .Declarations
using .Declarations: SortDeclaration, NamedSort, ArbitrarySort, PartitionSort
using .Declarations: OperatorDeclaration, NamedOperator, ArbitraryOperator, PartitionElement
using .Declarations: VariableDeclaration


include("terms/multisets.jl") # uses UserSort declaration
include("terms/constterm.jl")
include("terms/variables.jl")

include("terms/expressions.jl")
using .Expressions
#!using .Expressions: toexpr, PnmlExpr, BoolExpr, OpExpr

include("terms/operators.jl")

include("terms/terms.jl") # Variables and AbstractOperators preceed this.
include("Core/rewrite.jl")

include("Core/pnmlnetdata.jl") # Used by page, net; holds places, transitions, arcs.

#^ Above here are things that appear in  DeclDict contents.
#^ 2024-07-17 Changed DeclDict to be Any based,
#^ with the hope that the accessor methods provide type inferrability.
include("Core/decldict.jl") # Just contains show(). See decldictcore.jl.

#! 2025-04-09 move toolinfo and graphic to Labels

# Labels
include("Labels/Labels.jl")
using .Labels

# """
#     TOOLSPECIFIC_PARSERS

# Vector{ToolParser} of objects that associate a tool name and version with a callable.
# The callable parses the content of a `<toolspecific tool="toolname" version="string">`
# XML element.
# """
# const TOOLSPECIFIC_PARSERS = Labels.ToolParser[]#Labels.ToolParser( "org.pnml.tool", "1.0", Parser.tokengraphics_content)]

# Nodes #TODO make into a module?
include("nodes/nodes.jl") # Concrete place, transition, arc.
include("nodes/page.jl") # Contains nodes.
include("nodes/net.jl") # PnmlNet
include("nodes/model.jl") # Holds multiple PnmlNets.

include("NetAPI/netutils.jl") # API for Petri nets, graphs, et al.
include("NetAPI/enabling_rule.jl")
include("NetAPI/firing_rule.jl")
include("NetAPI/metagraph.jl")

include("Core/flatten.jl") # Apply to PnmlModel or PnmlNet #todo move to nodes?

# PARSE
include("Parser/Parser.jl")
using .Parser

# API Facade:
include("PNet/PNet.jl")
using .PNet

include("precompile.jl")

end # module PNML

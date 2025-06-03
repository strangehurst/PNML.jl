"""
[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, LabelledArrays, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.

What is accepted as values is ~~often~~ a superset of what a given pntd schema specifies.
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
using Logging
using LoggingExtras
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

    #app_env::String             = DEV
    verbose::Bool               = false
    base_path::String           = "PNML"
    log_path::String            = "log"
    log_level::Logging.LogLevel = Logging.Info
    log_to_file::Bool           = false
    log_requests::Bool          = true
    log_date_format::String     = "yyyy-mm-dd HH:MM:SS"

    warn_on_fixup::Bool         = false
    warn_on_namespace::Bool     = true
    warn_on_unclaimed::Bool     = false
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
import Base: eltype, keys
import Base: *, (+), (-), (<), (>),(>=), (<=), zero, length, iterate
import FunctionWrappers
import Reexport: @reexport
import DecFP
import Graphs
import MetaGraphsNext
import MacroTools
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import EzXML
import XMLDict
import Multisets: Multisets, Multiset
#~import StyledStrings

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using TermInterface
using Metatheory
using Graphs: SimpleDiGraphFromIterator, Edge
using MetaGraphsNext: MetaGraph

using LabelledArrays #Todo beware namespace pollution
using NamedTupleTools
using DocStringExtensions

# EXPORTS

export PnmlModel, PnmlNet, Page, Place, RefPlace, Transition, RefTransition, Arc
export REFID
export decldict

export @xml_str, xmlroot
public pnmlmodel
public PnmlException, MissingIDException, MalformedException
public usersort, namedsort
public labelof

Multisets.set_key_value_show()

include("logging.jl")
pnml_logger = Ref(logger_for_pnml(logfile(CONFIG[])::IOStream, CONFIG[].log_level))

#global_logger(pnml_logger[])
#@info """global logger\n$(current_logger())"""

include("PnmlTypeDefs.jl")
using .PnmlTypeDefs

include("PnmlIDRegistrys.jl")
using .PnmlIDRegistrys

"PNML ID registry of the current scope. Nets are the usual scope = a net-level-global."
const idregistry = ScopedValue{PnmlIDRegistry}() #! undefined until PnmlModel created XXXXXXXXXXXXXXXXXXX

include("Core/exceptions.jl")
include("Core/utils.jl")
include("Core/coordinates.jl")

include("context.jl")

include("Core/interfaces.jl") # Function docstrings mostly.
include("Core/types.jl") # Abstract Types with docstrings.
include("Core/anyelement.jl") # AnyElement, DictType, XDVT

include("Core/toolparser.jl")
include("Core/labelparser.jl")

include("Core/decldictcore.jl") # define things used by Sorts, Declarations

# parse context has id registry and DeclDict

# Parts of Labels and Nodes.

include("terms/tuples.jl")
include("Sorts/Sorts.jl") # used in Variables, Operators, Places
using .Sorts

include("terms/multisets.jl") # uses UserSort declaration
include("terms/constterm.jl")
include("terms/variables.jl")

include("terms/expressions.jl")
using .Expressions
#!using .Expressions: toexpr, PnmlExpr, BoolExpr, OpExpr

include("terms/operators.jl")

include("terms/terms.jl") # Variables and AbstractOperators preceed this.
include("Core/rewrite.jl")

# 2024-07-22 moved forward, holds Any rather than node types.
include("Core/pnmlnetdata.jl") # Used by page, net; holds places, transitions, arcs.

include("Declarations/Declarations.jl")
using .Declarations
import .Declarations: NamedSort, SortDeclaration

# Declarations are inside a <declaration> Label.
# NamedSort declaration wraps (ID, name, <:AbstractSort).
# UserSort is not a declaration, but a sort that refers to a declaration by REFID.

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
include("nodes/pagetree.jl") # AbstractTree used to print a PnmlNet.
include("nodes/model.jl") # Holds multiple PnmlNets.

include("NetAPI/netutils.jl") # API for Petri nets, graphs, et al.
include("NetAPI/enabling_rule.jl")
include("NetAPI/firing_rule.jl")
include("NetAPI/metagraph.jl")
#include("NetAPI/")

include("Core/flatten.jl") # Apply to PnmlModel or PnmlNet #todo move to nodes?

# PARSE
include("Parser/Parser.jl")
using .Parser

# API Facade:
include("PNet/PNet.jl")
using .PNet

include("precompile.jl")

end # module PNML

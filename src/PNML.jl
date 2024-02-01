"""
[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, LabelledArrays, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.

What is accepted as values is ~~often~~ usually a superset of what a given pntd schema specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

The pnml specification has layers.

The core layer is useful and extendable. The standard defines extensions of the core for
place-transition petri nets (integers) and high-level petri net graphs (many-sorted algebra).
This package family adds non-standard continuous net (float64) support.
Note that there is no RelaxNG schema file for these extensions

On top of the IR is (will be) implemented Petri Net adaptions and interpertations.
This is the level that pntd conformance can be imposed.
Adaption to julia packages for graphs, agents, and composing into the greater hive-mind.
"""
module PNML

# CONFIG structure copied from Tim Holy's Cthulhu.jl.
"""
Configuration with default values that can be overidden by a LocalPreferences.toml.
# Options
  - `indent_width::Int`: Indention of nested lines.
  - `lock_registry::Bool`: Lock registry with a `ReentrantLock`.
  - `text_element_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
  - `warn_on_fixup::Bool`: When an missing value is replaced by a default value, issue a warning.
  - `warn_on_namespace::Bool`: There are pnml files that break the rules & do not have an xml namespace.
  - `warn_on_unclaimed::Bool`: Issue warning when PNML label does not have a parser defined. While allowed, there will be code required to do anything useful with the label.
  - `verbose::Bool`: Print information as runs.
"""
Base.@kwdef mutable struct PnmlConfig
    indent_width::Int           = 4
    lock_registry::Bool         = true
    text_element_optional::Bool = true
    verbose::Bool           = false
    warn_on_fixup::Bool     = true
    warn_on_namespace::Bool = true
    warn_on_unclaimed::Bool = true
end

"See [`PnmlConfig`](@ref) for default values."
const CONFIG = PnmlConfig()

using Preferences
include("preferences.jl")

__init__() = read_config!(CONFIG)


# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

using AutoHashEquals
using Base: Fix1, Fix2, @kwdef, RefValue
using DocStringExtensions
using FunctionWrappers
import FunctionWrappers: FunctionWrapper
using LabelledArrays
using MLStyle: @match
using NamedTupleTools
import OrderedCollections: OrderedDict, OrderedSet, LittleDict
using Preferences
using Reexport
using DecFP
#using Infiltrator: @infiltrate
import Graphs
import MetaGraphsNext
#using DebuggingUtilities

import EzXML
import XMLDict

include("Core/PnmlTypeDefs.jl")
@reexport using .PnmlTypeDefs
include("Core/PnmlIDRegistrys.jl")
@reexport using .PnmlIDRegistrys

include("Core/exceptions.jl")
include("Core/utils.jl")
include("Core/xmlutils.jl")

include("Core/interfaces.jl") # Function docstrings
include("Core/types.jl") # Abstract Types
#include("Core/pprint.jl")

# Parts of Labels and Nodes.
include("Core/constterm.jl") #
include("Core/sorts.jl") # Sorts are used in Variables, Operators
include("Core/terms.jl") # Variables and Operators
include("Core/Terms/arbitrarydeclarations.jl")
include("Core/Terms/booleans.jl")
include("Core/Terms/cyclicenumerations.jl")
include("Core/Terms/dots.jl")
include("Core/Terms/finiteenumerations.jl")
include("Core/Terms/finiteintranges.jl")
include("Core/Terms/integers.jl")
include("Core/Terms/lists.jl")
include("Core/Terms/multisets.jl")
include("Core/Terms/partitions.jl")
include("Core/Terms/strings.jl")

include("Core/structure.jl")
include("Core/graphics.jl")
include("Core/toolinfos.jl")

# Labels
include("Core/labels.jl")
include("Core/name.jl")
include("Core/inscriptions.jl")
include("Core/markings.jl")
include("Core/conditions.jl")
include("Core/sorttype.jl")
include("Core/declarations.jl") # Declarations Label.
include("Core/rates.jl")

# Nodes
include("Core/nodes.jl") # Concrete place, transition, arc.
include("Core/pnmlnetdata.jl") # Used by page, net, holds places, transitions, arcs.
include("Core/page.jl")
include("Core/net.jl")
include("Core/pagetree.jl") # AbstractTree used to print a PnmlNet.
include("Core/model.jl") # Holds multiple PnmlNets.

include("Core/flatten.jl") # Apply to PnmlModel or PnmlNet

# Petri Nets
include("PNet/petrinet.jl")
include("PNet/transition_function.jl")
include("PNet/metagraph.jl")

# PARSE
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/terms.jl")
include("Parse/toolspecific.jl")

export @xml_str, xmlroot
export parse_str, parse_file, parse_pnml
export PnmlException, MissingIDException, MalformedException
export registry

include("precompile.jl")

end # module PNML

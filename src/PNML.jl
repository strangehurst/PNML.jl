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
  - `warn_on_unimplemented::Bool`: Issue warning to highlight something unimplemented. Expect high volume of messages.
  - `verbose::Bool`: Print information as runs.
"""
Base.@kwdef mutable struct PnmlConfig
    indent_width::Int           = 4
    lock_registry::Bool         = true
    text_element_optional::Bool = true
    verbose::Bool           = false
    warn_on_fixup::Bool     = false
    warn_on_namespace::Bool = true
    warn_on_unclaimed::Bool = false
    warn_on_unimplemented::Bool = false
end

using ScopedValues
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
import FunctionWrappers
import Reexport
import DecFP
import Graphs
import MetaGraphsNext
import OrderedCollections: OrderedDict, LittleDict, freeze
import EzXML
import XMLDict
import TermInterface
import Multisets: Multisets, Multiset
#~import StyledStrings
Multisets.set_key_value_show()

using LabelledArrays #Todo beware namespace pollution
using NamedTupleTools
using DocStringExtensions

include("Core/PnmlTypeDefs.jl")
Reexport.@reexport using .PnmlTypeDefs

include("Core/PnmlIDRegistrys.jl")
Reexport.@reexport using .PnmlIDRegistrys

# The registries are to remain available after the model has been returned. #& is this assertion true?

"Vector of ID registries of the same length as the number of nets. The registries may alias."
const IDRegistryVec::Vector{PnmlIDRegistry} = PnmlIDRegistry[]
"ID registry of the current scope. Nets are the usual scope = a net-level-global."
const idregistry = ScopedValue{PnmlIDRegistry}() # undefined

include("Core/exceptions.jl")
include("Core/utils.jl")
include("Core/xmlutils.jl")

include("Core/interfaces.jl") # Function docstrings
include("Core/types.jl") # Abstract Types

# Parts of Labels and Nodes.
include("Core/Terms/dots.jl")
include("Core/sorts.jl") # Sorts are used in Variables, Operators, Places
include("Core/declarations.jl") # Declarations are inside a <declaration> Label.
include("Core/Terms/arbitrarydeclarations.jl")
include("Core/constterm.jl") #
include("Core/Terms/booleans.jl")
include("Core/Terms/enumerations.jl")
#include("Core/Terms/finiteenumerations.jl")
#include("Core/Terms/finiteintranges.jl")
include("Core/Terms/numbers.jl")
include("Core/Terms/lists.jl")
include("Core/Terms/multisets.jl")
include("Core/Terms/strings.jl")
include("Core/Terms/variables.jl")
include("Core/Terms/partitions.jl")
include("Core/Terms/operators.jl")
include("Core/Terms/terms.jl") # Variables and AbstractOperators preceed this.
include("Core/Terms/tuples.jl")
include("Core/decldict.jl")
include("Core/structure.jl")
include("Core/graphics.jl")
include("Core/toolinfos.jl")

# Labels
include("Core/labels.jl")
include("Core/name.jl")
include("Core/sorttype.jl")
include("Core/inscriptions.jl")
include("Core/markings.jl")
include("Core/conditions.jl")
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

"""
Per-net dictionary of declaration dictionaries, [`DeclDict`](@ref), keyed by net id.
"""
const TOPDECLDICTIONARY::Dict{Symbol,DeclDict} = Dict{Symbol,DeclDict}()

export @xml_str, xmlroot
export parse_str, parse_file, parse_pnml
export PnmlException, MissingIDException, MalformedException

include("precompile.jl")

end # module PNML

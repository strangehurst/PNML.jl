"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML

# CONFIG structure copies from Tim Holy's Cthulhu.jl.
"""
Configuration with default values that can be overidden by a LocalPreferences.toml.
# Options
  - `indent_width::Int`: Indention of nested lines.
  - `warn_on_namespace::Bool`: There are pnml files that break the rules & do not have an xml namespace.
  - `text_element_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
  - `warn_on_fixup::Bool`: When an missing value is replaced by a default value, issue a warning.
  - `warn_on_unclaimed::Bool`: Issue warning when PNML label does not have a parser defined. While allowed, there will be code required to do anything useful with the label.
  - `verbose::Bool`: Print information as runs.
  - `lock_registry::Bool`: Lock registry with a `ReentrantLock`.
"""
Base.@kwdef mutable struct PnmlConfig
    indent_width::Int = 4
    warn_on_namespace::Bool = true
    text_element_optional::Bool = true
    warn_on_fixup::Bool = false
    warn_on_unclaimed::Bool = false
    verbose::Bool = false
    lock_registry::Bool = true
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
import EzXML
using FunctionWrappers
import FunctionWrappers: FunctionWrapper
using LabelledArrays
using MLStyle: @match
using NamedTupleTools
import OrderedCollections: OrderedDict, OrderedSet, LittleDict
using Preferences
using PrettyPrinting
import PrettyPrinting: quoteof
using Reexport
using DecFP
#using Infiltrator: @infiltrate
import Graphs
import MetaGraphsNext

include("Core/PnmlTypeDefs.jl")
@reexport using .PnmlTypeDefs
include("Core/PnmlIDRegistrys.jl")
@reexport using .PnmlIDRegistrys

include("Core/exceptions.jl")
include("Core/utils.jl")

include("Core/interfaces.jl") # Function docstrings
include("Core/types.jl") # Abstract Types

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

include("Core/show.jl")

# PARSE
include("Core/xmlutils.jl")
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/terms.jl")
include("Parse/toolspecific.jl")

export @xml_str,
    xmlroot,
    parse_str,
    parse_file,
    parse_pnml,
    PnmlException,
    MissingIDException,
    MalformedException

using PrecompileTools

PrecompileTools.@setup_workload begin
    PrecompileTools.@compile_workload begin

        #TODO ============================================
        #!        Do more precompile setup.
        #TODO ============================================

        metagraph(SimpleNet("""<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="small-net" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name> <text>P/T Net with one place</text> </name>
    <page id="page1">
      <place id="place1">
	    <initialMarking> <text>100</text> </initialMarking>
      </place>
      <transition id="transition1">
        <name><text>Some transition</text></name>
      </transition>
      <arc source="transition1" target="place1" id="arc1">
        <inscription><text>12</text></inscription>
      </arc>
    </page>
  </net>
</pnml>"""))
        #TODO High Level, Continuous
    end
end

end # module PNML

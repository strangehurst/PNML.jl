"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML

# CONFIG structure copies from Tim Holy's Cthulhu.jl.
"TODO"
Base.@kwdef mutable struct PnmlConfig
    indent_width::Int = 4
    warn_on_namespace::Bool = true
    text_element_optional::Bool = true
    warn_on_fixup::Bool = true #! false
    warn_on_unclaimed::Bool = true #! false
    verbose::Bool = true #! false
    lock_registry::Bool = true
end

"""
    PnmlConfig

Configuration options
# Options
  - `indent_width::Int`: Indention of nested lines. Defaults to `$(PnmlConfig().indent_width)`.
  - `warn_on_namespace::Bool`: There are pnml files that break the rules &
do not have an xml namespace. Initial state of toggle defaults to `true`.
  - `text_element_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
Initial state of warning toggle defaults to `true`.
  - `warn_on_fixup::Bool`: When an missing value is replaced by a default value,
issue a warning. Initial state of "warn_on_fixup" toggle defaults to `false`.
  - `warn_on_unclaimed::Bool`: Issue warning when PNML label does not have a parser defined.
While allowed, there will be code required to do anything useful with the label.
Initial state of "warn" toggle defaults to `false`.
  - `verbose::Bool`: Print information as runs.  Initial state of "verbose" toggle defaults to `false`.
  - `lock_registry::Bool`: Default is `true` to use a lock, deefault `Re`.
"""
const CONFIG = PnmlConfig()

using Preferences
include("preferences.jl")

__init__() = read_config!(CONFIG)


# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

using AbstractTrees
using AutoHashEquals
using Base: Fix1, Fix2, @kwdef, RefValue
using DocStringExtensions
using EzXML
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
#using Infiltrator: @infiltrate



include("Core/PnmlTypeDefs.jl")
@reexport using .PnmlTypeDefs
include("Core/PnmlIDRegistrys.jl")
@reexport using .PnmlIDRegistrys

include("Core/xmlutils.jl")
include("Core/exceptions.jl")
include("Core/utils.jl")

include("Core/interfaces.jl") # Function docstrings
include("Core/types.jl") # Abstract Types

include("HighLevel/terms.jl")
include("HighLevel/sorts.jl")
include("HighLevel/hldeclarations.jl")

include("Core/labels.jl")
include("Core/graphics.jl")
include("Core/toolinfos.jl")
include("Core/objcommon.jl")
include("Core/name.jl")

include("HighLevel/sorttype.jl")

include("HighLevel/hllabels.jl")

include("Core/inscriptions.jl")
include("HighLevel/hlinscriptions.jl")
include("Core/markings.jl")
include("HighLevel/hlmarkings.jl")
include("Core/conditions.jl")

include("Core/declarations.jl")

include("Core/defaults.jl")
include("HighLevel/hldefaults.jl")
include("HighLevel/structure.jl")

include("Core/nodes.jl")
include("Core/pnmlnetdata.jl") # Used by page, net.
include("Core/page.jl")
include("Core/net.jl")
include("Core/pagetree.jl")
include("Core/model.jl")

include("Core/flatten.jl")
include("Core/show.jl")

# High-Level
include("HighLevel/hlshow.jl")

# PARSE
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")

# Petri /Nets
include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")
include("Continuous/rates.jl")
include("Net/transition_function.jl")


export @xml_str,
    xmlroot,
    parse_str,
    parse_file,
    parse_pnml,
    parse_node,
    PnmlException,
    MissingIDException,
    MalformedException


#TODO ============================================
#TODO precompile setup.
#TODO ============================================

using PrecompileTools

PrecompileTools.@setup_workload begin
    #! data = ...
    PrecompileTools.@compile_workload begin
        #! call_some_code(data, ...)
    end
end

end # module PNML

"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML

# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

using EzXML
using MLStyle: @match
using DocStringExtensions
using AutoHashEquals
using PrettyPrinting
using AbstractTrees
using LabelledArrays
using Reexport

@reexport using PnmlTypeDefs
@reexport using PnmlIDRegistrys

include("xmlutils.jl")
include("exceptions.jl")
include("utils.jl")


# INTERMEDIATE REPRESENTATION

# PNML CORE

include("Core/interfaces.jl") # Function docstrings
include("Core/types.jl") # Abstract Types
include("Core/labels.jl")
include("Core/anyelement.jl")
include("Core/graphics.jl")
include("Core/toolinfos.jl")
include("Core/objcommon.jl")

include("Core/name.jl")

# High-Level
include("HighLevel/hltypes.jl")
include("HighLevel/structure.jl")
include("HighLevel/hllabels.jl")
include("HighLevel/declarations.jl")
include("HighLevel/terms.jl")
include("HighLevel/sorts.jl")


include("IR/defaults.jl")
include("IR/markings.jl")
include("IR/conditions.jl")
include("IR/inscriptions.jl")

include("IR/evaluate.jl")

include("IR/nodes.jl")
include("IR/page.jl")
include("IR/net.jl")
include("IR/model.jl")

include("IR/flatten.jl")
include("IR/show.jl")

# PARSE
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")

# PETRI NET
include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")
include("Net/rates.jl")
include("Net/transition_function.jl")

export @xml_str, PnmlDict,
    parse_str, parse_file, parse_pnml, parse_node,
    PnmlException, MissingIDException, MalformedException
end

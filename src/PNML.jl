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

include("config.jl")

#include("Base/PnmlBase.jl") #TODO sub module test
#@reexport using .PnmlBase

include("xmlutils.jl")
include("id.jl")
include("interfaces.jl")
include("types.jl")
include("exceptions.jl")
include("utils.jl")

#include("pnmltypes.jl")
#@reexport using .PnmlTypes

include("IR/intermediate.jl")

include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")

include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

export @xml_str, PnmlDict,
    parse_str, parse_file, parse_pnml, parse_node,
    PnmlException, MissingIDException, MalformedException
end

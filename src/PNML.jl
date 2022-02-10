"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML

using EzXML
using MLStyle: @match
using DocStringExtensions
using PrettyPrinting
#using Symbolics
#using IfElse
using AbstractTrees
using LabelledArrays
using SciMLBase: @add_kwonly
using Reexport
#include("docstrings.jl")

# """
# $(TYPEDSIGNATURES)

# Set value of key :xml based on a boolean control flag. Defaut is `true`.
# """
# includexml(node; INCLUDEXML=true)::Maybe{EzXML.Node} = INCLUDEXML ? node : nothing

include("config.jl")

#include("Base/PnmlBase.jl") #TODO sub module test
#@reexport using .PnmlBase

include("xmlutils.jl")
include("id.jl")
include("types.jl")
include("exceptions.jl")
include("pnmltypes.jl")
using .PnmlTypes

include("IR/intermediate.jl")

include("Parse/parseutils.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")
include("Parse/flatten.jl")
include("Parse/show.jl")

include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

export @xml_str,
    parse_str, parse_file, parse_pnml, parse_node,
    PnmlException, MissingIDException, MalformedException

end

"""
$(DocStringExtensions.README)
"""
module PNML
using DocStringExtensions
using PrettyPrinting
using EzXML
using Symbolics, Statistics, IfElse, AbstractTrees
using LabelledArrays
using MLStyle: @match

include("config.jl")

"""
$(TYPEDSIGNATURES)

Set value of key :xml based on global configuration/control variable.
"""
includexml(node)::Maybe{EzXML.Node} = INCLUDEXML ? node : nothing

include("utils.jl")
include("types.jl")
include("pntd.jl")
include("parse.jl")
include("parse_utils.jl")
include("graphics.jl")
include("declarations.jl")
include("toolspecific.jl")
include("exceptions.jl")
include("validate.jl")
include("maps.jl")

include("document.jl")
include("simplenet.jl")

#TODO update exports
export @xml_str
export parse_pnml, parse_node, parse_file, parse_str
export PnmlException, MissingIDException, MalformedException

end

"""
    PNML Module reads and parses a Petri Net Markup Language file.
"""
module PNML
using DocStringExtensions
using PrettyPrinting
using EzXML, Symbolics, Statistics, IfElse, AbstractTrees
using LabelledArrays
using MLStyle: @match

include("config.jl")

"Set value of key :xml based on global variable."
includexml(node)::Maybe{EzXML.Node} = INCLUDEXML ? node : nothing

include("utils.jl")
include("types.jl")
include("document.jl")
include("simplenet.jl")
include("pntd.jl")
include("parse.jl")
include("parse_utils.jl")
include("graphics.jl")
include("declarations.jl")
include("toolspecific.jl")
include("exceptions.jl")
include("validate.jl")
include("maps.jl")

export extract_pnml,  @xml_str, @pnml_str
export parse_pnml, parse_node, parse_file, parse_str
export PnmlException, MissingIDException, MalformedException

end

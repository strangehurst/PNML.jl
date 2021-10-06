module PNML
using DocStringExtensions

using EzXML, Symbolics, Statistics, IfElse, AbstractTrees
using LabelledArrays
using MLStyle: @match

"Include the XML as part of data."
const INCLUDEXML = false

"Set value of key :xml based on global variable."
function includexml!(d, node)
    if haskey(d, :xml)
        if INCLUDEXML
            @debug "adding d[:xml] = node"
            d[:xml] = node
        else
            d[:xml] = nothing
        end
    end
end

include("utils.jl")
include("types.jl")
include("document.jl")
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
export PnmlException, MissingIDException, MalformedException, node_summary

#export parse_cn, parse_ci, parse_bvar, parse_lambda, parse_piecewise

end

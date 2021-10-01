module PNML
using DocStringExtensions

using EzXML, Symbolics, Statistics, IfElse, AbstractTrees
using MLStyle: @match

const INCLUDEXML = false
function includexml!(d, node)
    if INCLUDEXML && !haskey(d, :xml)
        @debug "adding d[:xml] = node"
        d[:xml] = node
    end
end

include("utils.jl")
include("parse.jl")
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

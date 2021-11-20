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


"""
$(TYPEDSIGNATURES)

Set value of key :xml based on a control flag.
"""
includexml(node; INCLUDEXML=false)::Maybe{EzXML.Node} = INCLUDEXML ? node : nothing

include("config.jl")

include("utils.jl")
include("id.jl")
include("types.jl")
include("exceptions.jl")

include("pntd.jl")

include("parse.jl")
include("parse_utils.jl")
include("graphics.jl")
include("declarations.jl")
include("toolspecific.jl")
include("maps.jl")

include("Net/document.jl")
include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

#TODO update exports
export @xml_str
export parse_pnml, parse_node, parse_file, parse_str
export PnmlException, MissingIDException, MalformedException

end

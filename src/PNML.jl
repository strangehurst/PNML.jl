"""
$(DocStringExtensions.README)
"""
module PNML

using EzXML
using MLStyle: @match
using DocStringExtensions
using PrettyPrinting
#using Symbolics, Statistics
#using IfElse
using AbstractTrees
using LabelledArrays

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

include("Parse/parse.jl")
include("Parse/parse_utils.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/document.jl")
include("Parse/maps.jl")

include("pntd.jl")

include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

export @xml_str
export parse_str, parse_file, parse_pnml, parse_node
export PnmlException, MissingIDException, MalformedException

end

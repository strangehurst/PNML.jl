"""
$(DocStringExtensions.README)
"""
module PNML

using EzXML
using MLStyle: @match
using DocStringExtensions
using PrettyPrinting
using Symbolics, Statistics, IfElse, AbstractTrees
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

include("parse.jl")
include("parse_utils.jl")
include("graphics.jl")
include("declarations.jl")
include("toolspecific.jl")
include("document.jl")
include("maps.jl")

include("pntd.jl")

include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

export @xml_str
export parse_str, parse_file, parse_pnml, parse_node
export PnmlException, MissingIDException, MalformedException

end

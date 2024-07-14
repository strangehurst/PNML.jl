module Parser

import EzXML
#using Reexport
using DocStringExtensions
using ..PnmlIDRegistrys

include("xmlutils.jl")
include("parseutils.jl")
include("anyelement.jl")
include("parse.jl")
include("graphics.jl")
include("declarations.jl")
include("terms.jl")
include("toolspecific.jl")

export XMLNode

end

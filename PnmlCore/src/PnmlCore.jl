"""
Infrastructure implementing the core of the Petri Net Modeling Language.
Upon this base is built mechanisms for Place-Transition, High-Level Petri Nets,
and extensions.

$(DocStringExtensions.IMPORTS)
$(DocStringExtensions.EXPORTS)

"""
module PnmlCore

using EzXML
using MLStyle: @match
using DocStringExtensions
using AutoHashEquals
using PrettyPrinting
using AbstractTrees
using LabelledArrays
using Reexport
using Preferences
using Accessors
using Base: Fix1, Fix2
using OrderedCollections

@reexport using PnmlTypeDefs
@reexport using PnmlIDRegistrys

include("xmlutils.jl")
include("exceptions.jl")
include("utils.jl")

include("interfaces.jl") # Function docstrings
include("types.jl") # Abstract Types

include("labels.jl")
include("anyelement.jl")
include("graphics.jl")
include("toolinfos.jl")
include("objcommon.jl")
include("name.jl")

include("inscriptions.jl")
include("markings.jl")
include("conditions.jl")
include("declarations.jl")

include("defaults.jl")

include("nodes.jl")
include("page.jl")
include("net.jl")
include("pagetree.jl")
include("model.jl")

include("flatten.jl")
include("show.jl")

export @xml_str,
    xmlroot,
    PnmlDict,
    PnmlException,
    MissingIDException,
    MalformedException

end # module PnmlCore

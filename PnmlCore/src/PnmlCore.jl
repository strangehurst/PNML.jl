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
using NamedTupleTools
using FunctionWrappers
import FunctionWrappers: FunctionWrapper

include("PnmlTypeDefs.jl")
@reexport using .PnmlTypeDefs
include("PnmlIDRegistrys.jl")
@reexport using .PnmlIDRegistrys

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
include("pnmlnetdata.jl")
include("net.jl")
include("pagetree.jl")
include("model.jl")

include("flatten.jl")
include("show.jl")

# High-Level
include("HighLevel/hltypes.jl")
include("HighLevel/hldefaults.jl")
include("HighLevel/structure.jl")
include("HighLevel/hllabels.jl")
include("HighLevel/hldeclarations.jl")
include("HighLevel/terms.jl")
include("HighLevel/sorts.jl")
include("HighLevel/hlinscriptions.jl")
include("HighLevel/hlmarkings.jl")
include("HighLevel/hlshow.jl")

# PARSE
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")


# Parse
export @xml_str,
    xmlroot,
    PnmlDict,
    parse_str,
    parse_file,
    parse_pnml,
    parse_node

# Exceptions
export PnmlException,
    MissingIDException,
    MalformedException


end # module PnmlCore

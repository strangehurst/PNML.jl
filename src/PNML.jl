"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML

# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

using EzXML
using MLStyle: @match
using DocStringExtensions
using AutoHashEquals
using PrettyPrinting
using AbstractTrees
using LabelledArrays
using Reexport
using Preferences

@reexport using PnmlTypeDefs
@reexport using PnmlIDRegistrys

include("xmlutils.jl")
include("exceptions.jl")
include("utils.jl")

# PNML CORE
include("Core/interfaces.jl") # Function docstrings
include("Core/types.jl") # Abstract Types

include("Core/labels.jl")
include("Core/anyelement.jl")
include("Core/graphics.jl")
include("Core/toolinfos.jl")
include("Core/objcommon.jl")
include("Core/name.jl")

include("Core/inscriptions.jl")
include("Core/markings.jl")

include("Core/defaults.jl")

include("Core/nodes.jl")
include("Core/page.jl")
include("Core/net.jl")
include("Core/model.jl")

include("Core/flatten.jl")

# High-Level
include("HighLevel/hltypes.jl")
include("HighLevel/structure.jl")
include("HighLevel/hllabels.jl")
include("HighLevel/declarations.jl")
include("HighLevel/terms.jl")
include("HighLevel/sorts.jl")
include("HighLevel/hlinscriptions.jl")
include("HighLevel/hlmarkings.jl")
include("HighLevel/conditions.jl")

# PETRI NET
include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

include("Continuous/rates.jl")
include("Net/transition_function.jl")

include("IR/show.jl")
include("IR/evaluate.jl")

# PARSE
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")


export @xml_str,
    xmlroot,
    PnmlDict,
    parse_str,
    parse_file,
    parse_pnml,
    parse_node,
    PnmlException,
    MissingIDException,
    MalformedException
end

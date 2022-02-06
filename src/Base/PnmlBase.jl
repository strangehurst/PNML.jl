"""
Experiment in SubModules

$(DocStringExtensions.IMPORTS)
$(DocStringExtensions.EXPORTS)
"""
module PnmlBase

using DocStringExtensions
using Reexport
#using requires

# Could be many include/reexport pairs.
# These are each a submodule.
include("XmlUtils.jl")

@reexport using .XmlUtils

#function __init__() end

end

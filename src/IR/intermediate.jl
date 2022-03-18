# PNML Intermediate Representation
# Defines types instantiated on the upwards parse step using PnmlDicts 
# created on the downward (leaf-ward) parsing step.
# Enables use of dispatch to create higher-level constructs.

#module IR

include("graphics.jl")
include("structure.jl")
include("toolinfos.jl")
include("labels.jl")
include("common.jl")
include("markings.jl")
include("conditions.jl")
include("inscriptions.jl")
include("declarations.jl")
include("nodes.jl")
include("page.jl")
include("net.jl")
include("model.jl")

include("flatten.jl")
include("show.jl")

#end # module IR

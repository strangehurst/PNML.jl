#
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a <net> or <page> that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.

All the declarations in the <structure> are placed into a single per-net dictionary `ddict`.
The text, graphics, and tools fields are expected to be nothing, but are present because,
being labels, it is allowed.
"""
@kwdef struct Declaration <: Annotation
    text::Maybe{String} = nothing
    ddict::DeclDict # Wraps the one true data store for net.
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
end

PNML.decldict(d::Declaration) = d.ddict
Base.length(d::Declaration) = length(PNML.decldict(d))
Base.isempty(d::Declaration) = isempty(PNML.decldict(d))

function Base.show(io::IO, d::Declaration)
    print(io, nameof(typeof(d)), "(")
    show(io, text(d)); print(io, ", ")
    show(io, d.graphics); print(io, ", ")
    show(io, d.tools); print(io, ", ")
    show(io, decldict(d))
    print(io, ")")
end

#
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a <net> or <page> that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.

All the declarations in the <structure> are placed into
a single per-net dictionary collection `ddict`.
The text, graphics, and toolspecinfos fields are expected to be nothing,
but are present because, being labels, it is allowed.
"""
@kwdef struct Declaration <: Annotation
    text::Maybe{String} = nothing
    ddict::DeclDict #! The declaration data store for a net.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
end

function Base.show(io::IO, d::Declaration)
    print(io, nameof(typeof(d)), "(")
    show(io, text(d)); print(io, ", ")
    show(io, d.graphics); print(io, ", ")
    show(io, d.toolspecinfos); print(io, ", ")
    return print(io, ")")
end

function verify!(errors, decl::Declaration, verbose::Bool, idreg::PNML.IDRegistry)
    if isempty(decl.ddict)
        push!(errors, string("declaration dictionarys is empty: $decl")::String)
    end
    return errors
end

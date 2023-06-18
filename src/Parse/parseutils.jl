#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add `node` to `d[:labels]`, a vector of [`PnmlLabel`](@ref). Return updated `d[:labels]`.
"""
function add_label!(tup::NamedTuple, node::XMLNode, pntd, reg)
    if !hasproperty(tup, :labels) || isnothing(tup.labels)
        error("tuple must have tools") #! tup = merge(tup, (; :labels => PnmlLabel[]))
    end
    @assert tup.labels isa Vector{PnmlLabel} #! debug
    add_label!(tup.labels, node, pntd, reg)
    return tup
end

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, reg)
    CONFIG.verbose && println("add label! ", nodename(node))
    if CONFIG.warn_on_unclaimed
        let tag=nodename(node)
            if haskey(tagmap, tag) && tag != "structure"
                @info "$(tag) is known tag being treated as unclaimed."
            end
        end
    end
    label = PnmlLabel(unclaimed_label(node, pntd, reg), node)
    push!(v, label)
    return nothing
end

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
# """
# $(TYPEDSIGNATURES)

# Add [`ToolInfo`](@ref) to tuple. Return updated tuple.

# The UML from the _pnml primer_ (and schemas) use <toolspecific>
# as the tag name for instances of the type ToolInfo.
# """
# function add_toolinfo!(tup, node, pntd, reg)
#     CONFIG.verbose && println("add_toolinfo! tup")
#     if !hasproperty(tup, :tools) || isnothing(tup.tools)
#         error("tuple must have tools") #!tup = merge(tup, (; :tools => ToolInfo[]))
#     end
#     @assert tup.tools isa Vector{ToolInfo} #! debug
#     add_toolinfo!(tup.tools, node, pntd, reg)
#     return tup
# end

function add_toolinfo!(v::Vector{ToolInfo}, node, pntd, reg)
    ti = parse_toolspecific(node, pntd, reg)
    push!(v,ti)
    return nothing
end

"""
Does any toolinfo attached to `d` have a matching `toolname`.
"""
function has_toolinfo end

# tools vector
function has_toolinfo(v::Vector{<:NamedTuple},
                      toolname::AbstractString)
    has_toolinfo(v, Regex(toolname))
end
function has_toolinfo(v::Vector{<:NamedTuple},
                      toolname::AbstractString,
                      version::AbstractString)
    has_toolinfo(v, Regex(toolname), Regex(version))
end
function has_toolinfo(v::Vector{<:NamedTuple},
                      namerex::Regex,
                      versionrex::Regex=r"^.*$")
    any(v) do tool
       match(namerex, tool.toolname) && match(versionrex, tool.version)
    end
end

#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Return tags common to both pnml nodes and pnml labels.
See also: [`pnml_label_defaults`](@ref), [`pnml_node_defaults`](@ref).x
"""
function pnml_common_defaults()
    (; :graphics => nothing, :tools => ToolInfo[], :labels => PnmlLabel[])
end

"""
$(TYPEDSIGNATURES)

Merge `xs` with default pnml node tags.
See also: [`pnml_label_defaults`](@ref), [`pnml_common_defaults`](@ref).
"""
function pnml_node_defaults(xs...)
#    tup = pnml_common_defaults()
#    tup = merge(tup, (; :name => nothing,), (; xs...))
    tup = merge(pnml_common_defaults(), (name = nothing,), (; xs...))
    #println("node default tup = ", tup)
    return tup
end

"""
$(TYPEDSIGNATURES)

Merge `xs` with default common keys and annotation label keys `text` and `structure'.
See also [`pnml_node_defaults`](@ref), [`pnml_common_defaults`](@ref).
"""
function pnml_label_defaults(xs...)
    tup = merge(pnml_common_defaults(), (; :text => nothing, :structure => nothing), (; xs...))
    #println("label default tup = ", tup)
    return tup
end

#---------------------------------------------------------------------
"""

Update `d` with any graphics, tools, and label child of `node`.
Used by [`parse_pnml_object_common`](@ref) & [`parse_pnml_label_common`](@ref).

"""
# text, structure, name & graphics are singles;
# toolspecific & unclaimed label can be multiples
"""
$(TYPEDSIGNATURES)

Return updated tuple accumulating pnml object labels.
"""
function parse_pnml_object_common(tup0::NamedTuple, node::XMLNode, pntd::PnmlType, idreg::PnmlIDRegistry)
    tup = (; tup0...) #TODO copy?
    tag = EzXML.nodename(node)
    # if tag == "name" # Pnml objects have names but labels do not.
    #     tup = merge(tup, (; :name => parse_name(node, pntd, idreg)))
    # elseif tag == "graphics"
    #     tup = merge(tup, (; :graphics => parse_graphics(node, pntd, idreg)))
    # else
    if tag == "toolspecific"
        add_toolinfo!(tup.tools, node, pntd, idreg) #! make/add collection
    else
        # Note that here "labels" are the "everything else" option.
        # Tag should have been consumed before/instead of being treated as an anonymous label.
        add_label!(tup.labels, node, pntd, idreg) #! make/add collection
    end
    return tup #! TODO
end

"""
$(TYPEDSIGNATURES)

Update tuple with label of a pnml object.
"""
#function parse_pnml_label_common(node, pntd, reg)
#    tup = NamedTuple() #merge(tup, (tuplekind = "label",))  # start with a visual aid
function parse_pnml_label_common(tup::NamedTuple, node, pntd, reg)::NamedTuple
    tup = merge(tup, (tuplekind = "label",))  # start with a visual aid
    tag = EzXML.nodename(node)
    if tag == "text"
        t = parse_text(node, pntd, reg)
        tup = merge(tup, (text = t,))
    elseif tag == "structure"
        # Fallback since a "claimed" label's parser should have already consumed the tag.
        s = parse_structure(node, pntd, reg)
        tup = merge(tup, (structure = s,))
    elseif tag == "graphics"
        g = parse_graphics(node, pntd, reg)
        tup = merge(tup, (graphics = g,))
    elseif tag == "toolspecific"
        add_toolinfo!(tup.tools, node, pntd, reg) #! Add tool to collections
    end
    #@show tup
    return tup
end

#---------------------------------------------------------------------
"""
Parse string as a number. First try integer then float.
"""
function number_value(::Type{T}, s::AbstractString)::T where {T <: Number}
    x = tryparse(T, s)
    isnothing(x) && throw(ArgumentError("cannot parse '$s' as $T"))
    return x
end

#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add `node` to `d[:labels]`, a vector of [`PnmlLabel`](@ref). Return updated `d[:labels]`.
"""
function add_label!(d::PnmlDict, node::XMLNode, pntd, reg)
    # Pnml considers any "unknown" element to be a label. So initialized to `nothing
    # since it is expected that most labels will have defined tags and semantics and
    # not use this mechanisim. Convert to a vector on first use.
    if d[:labels] === nothing
        d[:labels] = PnmlLabel[]
    end
    add_label!(d[:labels], node, pntd, reg)
end
function add_label!(tup::NamedTuple, node::XMLNode, pntd, reg)
    if !hasproperty(tup, :labels) || isnothing(tup.labels)
        tup = merge(tup, namedtuple(:labels => PnmlLabel[]))
    end
    add_label!(tup.labels, node, pntd, reg)
end

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, reg)

    println("add label! ", nodename(node))

    if CONFIG.warn_on_unclaimed
        let tag=nodename(node)
            if haskey(tagmap, tag) && tag != "structure"
                @info "$(tag) is known tag being treated as unclaimed."
            end
        end
    end
    label = PnmlLabel(unclaimed_label(node, pntd, reg), node)
    push!(v, label)
    return v
end

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add [`ToolInfo`](@ref) `d[:tools]`. Return updated `d[:tools]`.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(dict::PnmlDict, node, pntd, reg)
    println("add_toolinfo! dict")
    if dict[:tools] === nothing
        dict[:tools] = ToolInfo[]
    end
    add_toolinfo!(dict[:tools], node, pntd, reg)
end
function add_toolinfo!(tup, node, pntd, reg)
    println("add_toolinfo! tup")
    @show typeof(tup)
    if !hasproperty(tup, :tools) || isnothing(tup.tools)
        tup = merge(tup, namedtuple(:tools => ToolInfo[]))
        println("  create tools[] ", typeof(tup))
    else
        println("  has vector ", typeof(tup))
    end
    @show typeof(tup.tools) #! debug
    add_toolinfo!(tup.tools, node, pntd, reg)
end

function add_toolinfo!(v::Vector{ToolInfo}, node, pntd, reg)
    @show "add_toolinfo! $(nodename(node))"
    ti = parse_toolspecific(node, pntd, reg) # Here is that tag name in use.
    push!(v,ti)
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

"""
Return first toolinfo having a matching toolname and version.
"""
function get_toolinfo end

get_toolinfo(ti::ToolInfo, name::AbstractString) = get_toolinfo(ti, Regex(name))
get_toolinfo(ti::ToolInfo, name::AbstractString, version::AbstractString) =
    get_toolinfo(ti, Regex(name), Regex(version))
get_toolinfo(ti::ToolInfo, name::AbstractString, versionrex::Regex) =
    get_toolinfo(ti, Regex(name),  versionrex)
get_toolinfo(ti::ToolInfo, namerex::Regex, versionrex::Regex=r"^.*$") =
    get_toolinfo([ti], namerex, versionrex)

get_toolinfo(v::Vector{ToolInfo}, name::AbstractString, version::AbstractString) =
    get_toolinfo(v, Regex(name), Regex(version))
get_toolinfo(v::Vector{ToolInfo}, name::AbstractString, versionrex::Regex) =
    get_toolinfo(v, Regex(name), versionrex)

function get_toolinfo(v::Vector{ToolInfo}, namerex::Regex, versionrex::Regex=r"^.*$")
    first(get_toolinfos(v, namerex, versionrex))
end

function get_toolinfos(v::Vector{ToolInfo}, namerex::Regex, versionrex::Regex=r"^.*$")
    filter(ti -> _match(ti, namerex, versionrex), v)
end

"""
    _match(ti::ToolInfo, name::AbstractString)
    _match(ti::ToolInfo, name::String, version::String)
    _match(ti::ToolInfo, namerex::Regex, versionrex::Regex)

Match toolname and version. Default is any version.
"""
function _match end
_match(ti::ToolInfo, name::AbstractString) = _match(ti.info, Regex(name))
_match(ti::ToolInfo, name::AbstractString, version::AbstractString) = _match(ti.inf, Regex(name), Regex(version))

function _match(ti::ToolInfo, namerex::Regex, versionrex::Regex = r"^.*$")
    #@show "match toolinfo $namerex, $versionrex"
    match_name = match(namerex, name(ti))
    match_version = match(versionrex, version(ti))
    !isnothing(match_name) && !isnothing(match_version)
end

#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Return tags common to both pnml nodes and pnml labels.
See also: [`pnml_label_defaults`](@ref), [`pnml_node_defaults`](@ref).x
"""
function pnml_common_defaults()
    #PnmlDict(:graphics => nothing, :tools => nothing, :labels => nothing)
    (; :graphics => nothing, :tools => nothing, :labels => nothing)
end

"""
$(TYPEDSIGNATURES)

Merge `xs` with default pnml node tags.
See also: [`pnml_label_defaults`](@ref), [`pnml_common_defaults`](@ref).
"""
function pnml_node_defaults(xs...)
    #dict = PnmlDict(pairs(pnml_common_defaults())..., :name => nothing, xs...)
    tup = merge(pnml_common_defaults(), (name = nothing,), (; xs...))
    return tup
end

"""
$(TYPEDSIGNATURES)

Merge `xs` with default common keys and annotation label keys `text` and `structure'.
See also [`pnml_node_defaults`](@ref), [`pnml_common_defaults`](@ref).
"""
function pnml_label_defaults(xs...)
    #dict =PnmlDict(pairs(pnml_common_defaults())..., :text => nothing, :structure => nothing, xs...)
    tup = merge(pnml_common_defaults(), (text = nothing, structure = nothing,), (; xs...))
    return tup
end

#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Update `d` with any graphics, tools, and label child of `node`.
Used by [`parse_pnml_node_common!`](@ref) & [`parse_pnml_label_common!`](@ref).

Note that "labels" are the "everything else" option and this should be called after parsing
any elements that has an expected tag. Any tag that is in an unexpected location
should be treated as an anonymous label.
"""
function parse_pnml_common!(d::PnmlDict, node::XMLNode, pntd::PnmlType, idreg::PnmlIDRegistry)
    tup = namedtuple(d)
    parse_pnml_common!(tup, node, pntd, idreg)
    d = PnmlDict(pairs(tup))
    return d
end
function parse_pnml_common!(tup::NamedTuple, node::XMLNode, pntd::PnmlType, idreg::PnmlIDRegistry)
    tag = EzXML.nodename(node)
    if tag == "graphics"
        tup = merge(tup, namedtuple(:graphics => parse_graphics(node, pntd, idreg)))
    elseif tag == "toolspecific"
        add_toolinfo!(tup, node, pntd, idreg)
    end
    return tup
end

"""
$(TYPEDSIGNATURES)

Update `d` with `name` children, defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_node_common!(d::PnmlDict, node::XMLNode, pntd::PnmlType, idreg::PnmlIDRegistry)
    error("uses PnmlDict")
    tup = namedtuple(d)
    parse_pnml_node_common!(tup, node, pntd, idreg)
    # if tag == "name"
    #     n = parse_name(node, pntd, reg)
    #     d[:name] = n
    # elseif tag == "graphics"
    #     g = parse_graphics(node, pntd, reg)
    #     d[:graphics] = g
    # elseif tag == "toolspecific"
    #     add_toolinfo!(d, node, pntd, reg)
    # else
    #     add_label!(d, node, pntd, reg)
    # end
    return d
end
function parse_pnml_node_common!(tup::NamedTuple, node::XMLNode, pntd::PnmlType, idreg::PnmlIDRegistry)
    tup = merge(tup, (tuplekind = "node",))  # start with a visual aid
    tag = EzXML.nodename(node)
    if tag == "name"
        n = parse_name(node, pntd, idreg)
        tup = merge(tup, (name = n,))
    elseif tag == "graphics"
        g = parse_graphics(node, pntd, idreg)
        tup = merge(tup, (graphics = g,))
    elseif tag == "toolspecific"
        add_toolinfo!(tup, node, pntd, idreg)
    else
        add_label!(tup, node, pntd, idreg)
    end
    #@show tup
    return tup
end

"""
$(TYPEDSIGNATURES)

Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_label_common!(d::PnmlDict, node, pntd, idreg)
    tup = namedtuple(d)
    parse_pnml_label_common!(tup, node, pntd, idreg)
    d = PnmlDict(pairs(tup))
end
function parse_pnml_label_common!(tup::NamedTuple, node, pntd, reg)
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
        add_toolinfo!(tup, node, pntd, reg)
    end
    #@show tup
    return tup
end

#---------------------------------------------------------------------
"""
Parse string as a number. First try integer then float.
"""
function number_value(::Type{T}, s::AbstractString) where {T <: Number}
    x = tryparse(T, s)
    isnothing(x) && throw(ArgumentError("cannot parse '$s' as $T"))
    return x
end

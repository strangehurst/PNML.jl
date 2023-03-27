#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add `node` to `d[:labels]`, a vector of [`PnmlLabel`](@ref). Return updated `d[:labels]`.
"""
function add_label!(d::PnmlDict, node::XMLNode, pntd, reg)
    # Pnml considers any "unknown" element to be a label .

    # Initialized to `nothing since it is expected that most labels
    # will have defined tags and semantics.
    # Will convert value to a vector on first use.
    if d[:labels] === nothing
        d[:labels] = PnmlLabel[]
    end
    add_label!(d[:labels], node, pntd, reg)
end

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, reg)

    println("add label! ", nodename(node))

    if CONFIG.warn_on_unclaimed
        let tag=nodename(node)
            #
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
function add_toolinfo!(d::PnmlDict, node, pntd, reg)
    if d[:tools] === nothing
        d[:tools] = ToolInfo[]
        #TODO TokenGraphics is a known flavor.
    end
    add_toolinfo!(d[:tools], node, pntd, reg)
end

function add_toolinfo!(v::Vector{ToolInfo}, node, pntd, reg)

    #@show "add_toolinfo! $(nodename(node))"

    ti = parse_toolspecific(node, pntd, reg) # Here is that tag name in use.
    push!(v,ti)
end

"""
Does any toolinfo attached to `d` have a matching `toolname`.
"""
function has_toolinfo end

# tools vector
function has_toolinfo(v::Vector{PnmlDict},
                      toolname::AbstractString)
    has_toolinfo(v, Regex(toolname))
end
function has_toolinfo(v::Vector{PnmlDict},
                      toolname::AbstractString,
                      version::AbstractString)
    has_toolinfo(v, Regex(toolname), Regex(version))
end
function has_toolinfo(v::Vector{PnmlDict},
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

Return PnmlDict of tags common to both pnml nodes and pnml labels.
See also: [`pnml_label_defaults`](@ref), [`pnml_node_defaults`](@ref).x
"""
function pnml_common_defaults()
    #PnmlDict(:graphics => nothing, :tools => nothing, :labels => nothing)
    (graphics = nothing, tools = nothing, labels = nothing)
end

"""
$(TYPEDSIGNATURES)

Merge `xs` into dictonary with default pnml node tags.
Used on: net, page ,place, transition, arc.
Usually default value will be `nothing` or empty vector.
See also: [`pnml_label_defaults`](@ref), [`pnml_common_defaults`](@ref).
"""
function pnml_node_defaults(xs...)

    #println()
    tup = merge(pnml_common_defaults(), (name = nothing,), (; xs...))
    #@show typeof(tup) tup
    dict = PnmlDict(pairs(pnml_common_defaults())..., :name => nothing, xs...)
    #@show typeof(dict) dict
    return dict
end

"""
$(TYPEDSIGNATURES)

Merge `xs` into dictonary with default common keys and
High-Level annotation label keys `text` and `structure'.

Used on pnml label below a [`AbstractPnmlNode`](@ref).

Notable differences from [`pnml_node_defaults`](@ref): text, structure, no name.
See also: [`pnml_common_defaults`](@ref).
"""
function pnml_label_defaults(xs...)
    #PnmlDict(pnml_common_defaults(node)..., :text => nothing, :structure => nothing, xs...)
    PnmlDict(pairs(pnml_common_defaults())..., :text => nothing, :structure => nothing, xs...)
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
function parse_pnml_common!(d::PnmlDict, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    tag = EzXML.nodename(node)
    if tag == "graphics"
        d[:graphics] = parse_graphics(node, pntd, reg)
    elseif tag == "toolspecific"
        add_toolinfo!(d, node, pntd, reg)
    end
    return d
end

function parse_pnml_common_tup!(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)

    tup = (; :tuple => "base")  # strart with a visuial aid
    tag = EzXML.nodename(node)
    # tools and labels were vectors, change to nested tuple?
    if tag == "graphics"
        merge!(tup, :graphics => parse_graphics(node, pntd, reg))
    elseif tag == "toolspecific"
        merge!(tup, :tools => add_toolinfo!(d, node, pntd, reg))
    end
    return tup
end

"""
$(TYPEDSIGNATURES)

Update `d` with `name` children, defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_node_common!(d::PnmlDict, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    tup = (; :tuple => "node")  # strart with a visuial aid
    tag = EzXML.nodename(node)
    if tag == "name"
        d[:name] = parse_name(node, pntd, reg)
    elseif tag == "graphics"
        d[:graphics] = parse_graphics(node, pntd, reg)
    elseif tag == "toolspecific"
        add_toolinfo!(d, node, pntd, reg)
    else
        add_label!(d, node, pntd, reg)
    end
    return d
end






"""
$(TYPEDSIGNATURES)

Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_label_common!(d::PnmlDict, node, pntd, reg)
    tup = (; :tuple => "label")  # strart with a visuial aid
    tag = EzXML.nodename(node)
    if tag == "text"
        d[:text] = parse_text(node, pntd, reg)
    elseif tag == "structure"
        # Fallback since a "claimed" label's parser should have already consumed the tag.
        d[:structure] = parse_structure(node, pntd, reg)
    elseif tag == "graphics"
        d[:graphics] = parse_graphics(node, pntd, reg)
    elseif tag == "toolspecific"
        add_toolinfo!(d, node, pntd, reg)
    end
    return d
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

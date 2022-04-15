#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add `node` to `d[:labels]`, a vector of [`PnmlLabel`](@ref). Return updated `d[:labels]`.
"""
function add_label!(d::PnmlDict, node, pntd; kw...)
    # Pnml considers any "unknown" element to be a label so its key is `:labels`.

    # The value is initialized to `nothing since it is expected that most labels
    # will have defined tags and semantics. And be given a key `:tag`.
    # Will convert value to a vector on first use.
    if d[:labels] === nothing
        d[:labels] = PnmlLabel[]
    end
    add_label!(d[:labels], node, pntd; kw...)
end

function add_label!(v::Vector{PnmlLabel}, node, pntd; kw...)
    #@show "add label! $(nodename(node))"
    haskey(tagmap, node.name) && @info "$(node.name) is known tag being treated as unclaimed."
    label = PnmlLabel(unclaimed_label(node, pntd; kw...), node) #TODO handle types
    haskey(tagmap, node.name) && @info "$(node.name) parsed to type $(typeof(label))."
    push!(v, label)
    return
end

"""
Does any label attached to `d` have a matching `tagvalue`.

$(TYPEDSIGNATURES)
"""
function has_label end
function has_label(d::PnmlDict, tagvalue::Symbol)
    has_label(d[:labels], tagvalue)
end
function has_label(d::Vector{PnmlDict}, tagvalue::Symbol)
    any(label->tag(label) === tagvalue, d[:labels])
end


"""
$(TYPEDSIGNATURES)

Return first label attached to `d` have a matching `tagvalue`.
"""
function get_label end

function get_label(v::Vector{PnmlDict}, tagvalue::Symbol)
    #@show "get_label $(typeof(v)) size $(length(v)) $tagvalue"
    getfirst(lab->tag(lab) === tagvalue, v)
end

function get_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    #@show "get_label $tagvalue $v"
    getfirst(l->tag(l) === tagvalue, v)
end

# Vector of labels may be contained in a dictonary.
function get_label(d::PnmlDict, tagvalue::Symbol)
    #@show d[:labels]
    get_label(d[:labels], tagvalue)
end


#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add [`ToolInfo`](@ref) `node` to `d[:tools]`. Return updated `d[:tools]`.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(d::PnmlDict, node, pntd; kw...)
    if d[:tools] === nothing
        d[:tools] = ToolInfo[] #TODO: Pick type based on PNTD/Trait?
        #TODO TokenGraphics is a known flavor.
        #TODO Tools may induce additional subtype, but if is hoped that
        #TODO label based parsing is general & flexible enough to suffice.
    end
    add_toolinfo!(d[:tools], node, pntd; kw...)
end

function add_toolinfo!(v::Vector{ToolInfo}, node, pntd; kw...)
    ti = parse_toolspecific(node, pntd; kw...) # Here is that tag name in use.
    push!(v,ti)
end

"""
$(TYPEDSIGNATURES)

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
$(TYPEDSIGNATURES)

Return first toolinfo having a matching toolname and version.
"""
function get_toolinfo end

get_toolinfo(ti::ToolInfo, name::AbstractString) = get_toolinfo([ti], Regex(name)) 
get_toolinfo(ti::ToolInfo, name::AbstractString, version::AbstractString) = 
    get_toolinfo([ti], Regex(name), Regex(version)) 
 
function get_toolinfo(v::Vector{ToolInfo}, namerex::Regex, versionrex::Regex=r"^.*$")
    #@show "match toolinfo $(typeof(v)) $namerex $versionrex"
    getfirst(ti -> _match(ti, namerex, versionrex), v) 
end

"""
$(TYPEDSIGNATURES)
Match toolname and version.
"""
function _match end
function _match(ti::ToolInfo, name::AbstractString)
    #@show "match toolinfo $name"
    _match(ti.info, Regex(name))
end
function _match(ti::ToolInfo, name::String, version::String)
    #@show "match toolinfo $name, $version"
    _match(ti.inf, Regex(name), Regex(version))
end
function _match(ti::ToolInfo, namerex::Regex, versionrex::Regex=r"^.*$")
    #@show "match toolinfo $namerex ,$versionrex"
    !isnothing(match(namerex, ti.toolname)) && !isnothing(match(versionrex, ti.version))
end

#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Return Dict of tags common to both pnml nodes and pnml labels.
See also: [`pnml_label_defaults`](@ref), [`pnml_node_defaults`](@ref).
"""
function pnml_common_defaults(node)
    PnmlDict(:graphics => nothing, # graphics tag is single despite the 's'.
             :tools => nothing, # Here the 's' indicates multiples are allowed.
             :labels => nothing) # ditto
end

"""
$(TYPEDSIGNATURES)

Merge `xs` into dictonary with default pnml node tags.
Used on: net, page ,place, transition, arc.
Usually default value will be `nothing` or empty vector.
See also: [`pnml_label_defaults`](@ref), [`pnml_common_defaults`](@ref).
"""
function pnml_node_defaults(node, xs...)
    PnmlDict(pnml_common_defaults(node)...,
             :name => nothing,
             xs...)
end

"""
$(TYPEDSIGNATURES)

Merge `xs` into dictonary with default pnml HLannotation label tags.
Used on pnml tags below a [`PnmlNode`](@ref) tag.
Label level tags include: name, inscription, initialMarking.
Notable differences from [`pnml_node_defaults`](@ref): text, structure, no name tag.
See also: [`pnml_common_defaults`](@ref).
"""
function pnml_label_defaults(node, xs...)
    PnmlDict(pnml_common_defaults(node)...,
             :text => nothing,
             :structure => nothing,
             xs...)
end


#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Update `d` with any graphics, tools, and label child of `node`.
Used by [`parse_pnml_node_common!`](@ref) & [`parse_pnml_label_common!`](@ref).

Note that "labels" are the "everything else" option and this should be called after parsing
any elements that has an expected tag. Any tag that is encountered in an unexpected location
should be treated as an anonymous label for parsing.
"""
function parse_pnml_common!(d::PnmlDict, node, pntd; kw...)
    @match nodename(node) begin
        "graphics"     => (d[:graphics] = parse_graphics(node, pntd; kw...))
        "toolspecific" => add_toolinfo!(d, node, pntd; kw...)
        _ => add_label!(d, node, pntd; kw...) # label with a label allows any node to be attached & parsable.
    end
end

"""
$(TYPEDSIGNATURES)

Update `d` with `name` children, defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_node_common!(d::PnmlDict, node, pntd; kw...)
    @match nodename(node) begin
        "name" => (d[:name] = parse_name(node, pntd; kw...))
        _ => parse_pnml_common!(d, node, pntd; kw...)
    end
end

"""
$(TYPEDSIGNATURES)

Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_label_common!(d::PnmlDict, node, pntd; kw...)
    @match nodename(node) begin
        "text"      => (d[:text] = parse_text(node, pntd; kw...))
        # This is the fallback as "claimed" label's parser
        # should have already consumed the <structure>.
        "structure" => (d[:structure] = parse_structure(node, pntd; kw...))
        _ => parse_pnml_common!(d, node, pntd; kw...)
    end
end

#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Parse string as a number. First try integer then float.
"""
function number_value(s::AbstractString)
    x = tryparse(Int, s)
    x = isnothing(x) ?  tryparse(Float64, s) : x
end

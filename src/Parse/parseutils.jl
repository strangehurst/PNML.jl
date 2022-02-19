# Uses PnmlDict descending the XML during parsing.
# PnmlDict turned into Intermediate Representation forms on the return up the tree.

# Start with some generic functions that are shared with the IR.

"""
$(TYPEDSIGNATURES)

Return pnml id symbol, if argument has one, otherwise return `nothing`.
"""
function pid end
pid(::Any) = nothing
pid(node::PnmlDict)::Symbol = node[:id]

"""
$(TYPEDSIGNATURES)

Return tag symbol, if argument has one, otherwise `nothing`.
"""
function tag end
tag(::Any) = nothing
tag(pdict::PnmlDict)::Symbol = pdict[:tag]


"""
$(TYPEDSIGNATURES)

Return xml node field of `d` or `nothing`.
"""
function xmlnode end
xmlnode(::Any) = nothing
xmlnode(pdict::PnmlDict) = pdict[:xml]


"""
$(TYPEDSIGNATURES)

Does object have XML attached? Defaults to `false`.
"""
function has_xml end
has_xml(::Any) = false


"""
If `x` is `nothing` return `non`, otherwise return `x`.
"""
onnothing(x, non) = isnothing(x) ? non : x
onnothing(d::PnmlDict, s::Symbol, default) =
    isnothing(get(d, s, nothing)) ? default : d[s]

"""
$(TYPEDSIGNATURES)

Return PnmlDict holding parsed contents of a well-formed XML node.

If element `node` has any children, each is placed in the dictonary with the
tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value pairs.

# Details

This will recursivly descend the well-formed XML.
It is possible that claimed labels will be in the unclaimed element's content.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hiearchy.

# Examples

```jldoctest
julia> using PNML, EzXML

julia> node = PNML.parse_node(xml\"<aaa id=\\"FOO\\">BAR</aaa>\"; reg=PNML.IDRegistry())
PNML.PnmlLabel Dict(:tag => :aaa, :id => "FOO", :content => "BAR")
```
"""
function unclaimed_element(node; kw...)
    @debug "unclaimed = $(nodename(node))"
    @assert haskey(kw, :reg)
    # ID attributes can appear in various places. Each is unique and added to the registry.
    EzXML.haskey(node, "id") && register_id!(kw[:reg], node["id"])

    # Extract XML attributes.
    d = PnmlDict(:tag => Symbol(nodename(node)),
                 (Symbol(a.name) => a.content for a in eachattribute(node))...)
    _harvest!(d, node; kw...)
    return d
end

"Update `dict` with content or children"
function _harvest!(dict::PnmlDict, node::XMLNode; kw...)
    children = elements(node)
    if !isempty(children)
        merge!(dict, unclaimed_content(children; kw...))
    else
        dict[:content] = isempty(nodecontent(node)) ? nothing : strip(nodecontent(node))
    end
    dict
end

"""
$(TYPEDSIGNATURES)

Return PnmlDict with values that are vectors when there 
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function unclaimed_content(nodes::Vector{XMLNode}; kw...)
    d = PnmlDict()
    nnamevec = [nodename(node) => node for node in nodes] # Not yet turned into Symbols.
    tagnames = unique(map(first, nnamevec))
    foreach(tagnames) do tagname
        tags = filter(x->x.first===tagname, nnamevec)
        #TODO make toolspecific match annotation labels.declarations
        d[Symbol(tagname)] = if length(tags) > 1 # Now its a symbol.
            parse_node.(map(x->x.second, tags); kw...) #vector
        else
            parse_node(tags[1].second; kw...) #scalar
        end
    end
    d
end


#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add `node` to` d[:labels]`, a vector of PnmlLabel. Return updated `d[:labels]`.
"""
function add_label!(d::PnmlDict, node; kw...)
    # Pnml considers any "unknown" element to be a label so its key is `:labels`.

    # The value is initialized to `nothing since it is expected that most labels
    # will have defined tags and semantics. And be given a key `:tag`.
    # Will convert value to a vector on first use.
    if d[:labels] === nothing
        d[:labels] = PnmlLabel[]
    end
    add_label!(d[:labels], node; kw...)
end
function add_label!(v::Vector{PnmlLabel}, node; kw...)
    #@show "add label! $(nodename(node))"
    haskey(tagmap, node.name) && @info "$(node.name) is known tag being treated as unclaimed."
    # Use of parse_node here allows the :labels vector to contain fully parsed nodes.
    l = parse_node(node; kw...) #TODO handle types
    haskey(tagmap, node.name) && @info "$(node.name) parsed to type $(typeof(l))."
    push!(v, l)
end

"""
Does any label attached to `d` have a matching `tagvalue`.

---
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
    @show "get_label $(typeof(v)) size $(length(v)) $tagvalue"
    i = findfirst(lab->tag(lab) === tagvalue, v)
    !isnothing(i) ? v[i] : nothing
end

function get_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    @show "get_label $(typeof(v)) size $(length(v)) $tagvalue"
    i = findfirst(lab->tag(lab) === tagvalue, v)
    !isnothing(i) ? v[i] : nothing
end

# Vector of labels may be contained in a dictonary.
function get_label(d::PnmlDict, tagvalue::Symbol)
    @debug d[:labels]
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
function add_toolinfo!(d::PnmlDict, node; kw...)
    if d[:tools] === nothing
        d[:tools] = ToolInfo[] #TODO: Pick type based on PNTD/Trait?
        #TODO DefaultTool and TokenGraphics are 2 known flavors.
        #TODO Tools may induce additional subtype, but if is hoped that
        #TODO label based parsing is general & flexible enough to suffice.
    end
    add_toolinfo!(d[:tools], node; kw...)
end

function add_toolinfo!(v::Vector{ToolInfo}, node; kw...)
    ti = parse_toolspecific(node; kw...) # Here is that tag name in use.
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
    @show
    any(v) do tool
       match(namerex, tool.toolname) && match(versionrex, tool.version)
    end
end

#----------------
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
    i = findfirst(v) do ti
        _match(ti, namerex, versionrex)
    end
    return !isnothing(i) ? v[i] : nothing
end

#----------------
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

Merge `xs` into dictonary with default pnml label tags.
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
function parse_pnml_common!(d::PnmlDict, node; kw...)
    @match nodename(node) begin
        "graphics"     => (d[:graphics] = parse_node(node; kw...))
        "toolspecific" => add_toolinfo!(d, node; kw...)
        _ => add_label!(d, node; kw...) # label with a label allows any node to be attached & parsable.
    end
end

"""
$(TYPEDSIGNATURES)

Update `d` with `name` children, defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_node_common!(d::PnmlDict, node; kw...)
    @match nodename(node) begin
        "name" => (d[:name] = parse_node(node; kw...))
        _      => parse_pnml_common!(d, node; kw...)
    end
end

"""
$(TYPEDSIGNATURES)

Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_label_common!(d::PnmlDict, node; kw...)
    @match nodename(node) begin
        "text"      => (d[:text] = parse_node(node; kw...)) #TODO label with name?
        "structure" => (d[:structure] = parse_node(node; kw...))
        _      => parse_pnml_common!(d, node; kw...)
    end
end

"""
$(TYPEDSIGNATURES)

Parse string as a number. First try integer then float.
"""
function number_value(s::AbstractString)
    x = tryparse(Int, s)
    x = isnothing(x) ?  tryparse(Float64, s) : x
end

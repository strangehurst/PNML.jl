"""
Return PnmlDict holding contents of a well-formed XML node.
Expected to be wrapped by a type, not be inside anothe Dict.

$(TYPEDSIGNATURES)

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

julia> node = PNML.parse_node(xml\"<aaa id=\\"FOO\\">BAR</aaa>\"; reg=PNML.IDRegistry());
```
"""
function unclaimed_element(node; kw...)::PnmlDict
    @debug "unclaimed = $(nodename(node))"
    @assert haskey(kw, :reg)
    # ID attributes can appear in various places. Each is unique and added to the registry.
    has_id(node) && register_id!(kw[:reg], node["id"])

    # Extract XML attributes.
    d = PnmlDict(:tag => Symbol(nodename(node)),
                 (Symbol(a.name) => a.content for a in eachattribute(node))...)

    # Harvest content or children.
    e = elements(node)
    if !isempty(e)
        merge!(d, unclaimed_content(e; kw...)) # children elements
    else
        d[:content] = isempty(nodecontent(node)) ? nothing : strip(nodecontent(node))
    end
    d[:xml] = includexml(node)

    d
end

"""
From `nv`, a vector of XML nodes, return PnmlDict with values that are vectors
when there are multiple instances of a tag in `nv` and scalar otherwise.

$(TYPEDSIGNATURES)
"""
function unclaimed_content(nv::Vector{EzXML.Node}; kw...)
    d = PnmlDict()
    nn = [nodename(n) => n for n in nv] # Not yet turned into Symbols.
    tagnames = unique(map(first, nn))
    foreach(tagnames) do tname
        e = filter(x->x.first===tname, nn)
        #TODO make toolspecific match annotation labels.declarations
        d[Symbol(tname)] = if length(e) > 1
            parse_node.(map(x->x.second, e); kw...) #vector
        else
            parse_node(e[1].second; kw...) #scalar
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
    if d[:labels] === nothing
        d[:labels] = PnmlLabel[]
    end
    add_label!(d[:labels], node; kw...)
end
function add_label!(v::Vector{PnmlLabel}, node; kw...)
    #@show "add label! $(nodename(node))"
    # Pnml considers any "unknown" element to be a label so its key is `:labels`.
    # The value is initialized to `nothing since it is expected that most labels
    # will have defined tags and semantics. And be given a key `:tag`.
    # Will convert value to a vector on first use.
    # Use of parse_node allows the :labels vector to contain fully parsed nodes.
    l = parse_node(node; kw...) #TODO handle types
    #@debug typeof(l)
    push!(v, l) #TODO specialized types not just PnmlDicts.
end

"""
Does any label attached to `d` have a matching `tagvalue`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function has_label end
function has_label(d::PnmlDict, tagvalue::Symbol)
    has_label(d[:labels], tagvalue)
end
function has_label(d::Vector{PnmlDict}, tagvalue::Symbol)
    any(label->tag(label) === tagvalue, d[:labels])
end


"""
Return first label attached to `d` have a matching `tagvalue`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function get_label end

function get_label(v::Vector{PnmlDict}, tagvalue::Symbol)
    @show "get_label $(typeof(v)) size $(length(v)) $tagvalue"
    i = findfirst(lab->tag(lab) === tagvalue, v)
    v[i]
end

function get_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    @show "get_label $(typeof(v)) size $(length(v)) $tagvalue"
    i = findfirst(lab->tag(lab) === tagvalue, v)
    v[i]
end

# Vector of labels may be contained in a dictonary.
function get_label(d::PnmlDict, tagvalue::Symbol)
    labels = d[:labels]
    @debug labels
    get_label(labels, tagvalue)
end


#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
Add `node` to `d[:tools]`. Return updated `d[:tools]`.

$(TYPEDSIGNATURES)

# DETAILS

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
    ti = parse_toolspecific(node; kw...)
    push!(v,ti)
end

"""
Does any toolinfo attached to `d` have a matching `toolname`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
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
function match(ti::ToolInfo, namerex::AbstractString)
    @show "match toolinfo $namerex"
    match(ti.info, Regex(namerex))
end
function match(ti::ToolInfo, namerex::String, versionrex::String)
    @show "match toolinfo $namerex"
    match(ti.inf, Regex(namerex), Regex(versionrex))
end
function match(ti::ToolInfo, namerex::Regex, versionrex::Regex=r"^.*$")
    @show "match toolinfo $namerex"
    match(namerex, ti.toolname) && match(versionrex, ti.version)
end

#----------------
"""
Return first toolinfo having a matching `toolname` and version.

A `Toolinfo` wraps a vector of PnmlDict with each element

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function get_toolinfo end

# identity
get_toolinfo(ti::ToolInfo, args...) = ti

#function get_toolinfo(v::Vector{ToolInfo}, toolname::AbstractString)
#    get_toolinfo(v, Regex(toolname))
#end
#function get_toolinfo(v::Vector{ToolInfo}, toolname::AbstractString, version::AbstractString)
#    get_toolinfo(v, Regex(toolname), Regex(version))
#end

function get_toolinfo(v::Vector{ToolInfo}, namerex::Regex, versionrex::Regex=r"^.*$")
    @show "match toolinfo $(typeof(v)) $namerex $versionrex"
    i = findfirst(v) do ti
        match(ti.info, namerex, versionrex)
    end
    v[i]
end


#---------------------------------------------------------------------
#---------------------------------------------------------------------
"""
Return Dict of tags common to both pnml nodes and pnml labels.
See also: [`pnml_label_defaults`](@ref), [`pnml_node_defaults`](@ref).

$(TYPEDSIGNATURES)
"""
function pnml_common_defaults(node)
    PnmlDict(:graphics => nothing, # graphics tag is single despite the 's'.
             :tools => nothing, # Here the 's' indicates multiples are allowed.
             :labels => nothing,# ditto
             :xml => includexml(node))
end

"""
Merge `xs` into dictonary with default pnml node tags.
Used on: net, page ,place, transition, arc.
Usually default value will be `nothing` or empty vector.
See also: [`pnml_label_defaults`](@ref), [`pnml_common_defaults`](@ref).

$(TYPEDSIGNATURES)
"""
function pnml_node_defaults(node, xs...)
    PnmlDict(pnml_common_defaults(node)...,
             :name => nothing,
             xs...)
end

"""
Merge `xs` into dictonary with default pnml label tags.
Used on pnml tags below a pnml_node tag.
Label level tags include: name, inscription, initialMarking.
Notable differences from [`pnml_node_defaults`](@ref): text, structure, no name tag.
See also: [`pnml_common_defaults`](@ref).

$(TYPEDSIGNATURES)
"""
function pnml_label_defaults(node, xs...)::PnmlDict
    PnmlDict(pnml_common_defaults(node)...,
             :text => nothing,
             :structure => nothing,
             xs...)
end


#---------------------------------------------------------------------
"""
Update `d` with any graphics, tools, and label child of `node`.
Used by [`parse_pnml_node_common!`](@ref) & [`parse_pnml_label_common!`](@ref).

Note that "labels" are the "everything else" option and this should be called after parsing
any elements that has an expected tag. Any tag that is encountered in an unexpected location
should be treated as an anonymous label for parsing.

$(TYPEDSIGNATURES)
"""
function parse_pnml_common!(d::PnmlDict, node; kw...)
    @match nodename(node) begin
        "graphics"     => (d[:graphics] = parse_node(node; kw...))
        "toolspecific" => add_toolinfo!(d, node; kw...)
        _ => add_label!(d, node; kw...) # label with a label allows any node to be attached & parsable.
    end
end

"""
Update `d` with `name` children, defering other tags to [`parse_pnml_common!`](@ref).

$(TYPEDSIGNATURES)
"""
function parse_pnml_node_common!(d::PnmlDict, node; kw...)
    @match nodename(node) begin
        "name" => (d[:name] = parse_node(node; kw...))
        _      => parse_pnml_common!(d, node; kw...)
    end
end

"""
Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).

$(TYPEDSIGNATURES)
"""
function parse_pnml_label_common!(d::PnmlDict, node; kw...)
    @match nodename(node) begin
        "text"      => (d[:text] = parse_node(node; kw...)) #TODO label with name?
        "structure" => (d[:structure] = parse_node(node; kw...))
        _      => parse_pnml_common!(d, node; kw...)
    end
end

#---------------------------------------------------------------------
"""
Should not often have a '<label>' tag, this will bark if one is found.
Return minimal PnmlDict holding (tag,node), to defer parsing the xml.

$(TYPEDSIGNATURES)
"""
function parse_label(node; kw...)
    nn = nodename(node)
    nn == "label" || error("element name wrong: $nn")
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag=>Symbol(nn), :xml=>node) # Always add xml because this is unexpected.
end

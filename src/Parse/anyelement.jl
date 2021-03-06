"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping a `tag` symbol and `PnmlDict` holding 
a well-formed XML node.

See [`ToolInfo`](@ref) for one intended use-case and [`unclaimed_label`](@ref) for when
a pnml label is expected but does not have a parser or the tag appears in an 
unexpected place.
"""
function anyelement end
anyelement(node; kw...) =  anyelement(node, PnmlCore(); kw...)
function anyelement(node, pntd; kw...)::AnyElement    
    d = _harvest_any!(node, pntd, _harvest_any!; kw...)
    return AnyElement(Symbol(nodename(node)) => d, node)
end

"""
$(TYPEDSIGNATURES)

Return `tag` => `PnmlDict` holding a pnml label and its children.

The main use-case is to wrap in a [`PnmlLabel`](@ref), [`Structure`](@ref),
[`Term`](@ref) or other specialized label. These wrappers add type to the 
nested dictonary holding the contents of the label.

Differs from `AnyElement` in that any id attribute of `node`
will be registered in [`IDRegistry`](@ref) as a unique identifier.
"""
function unclaimed_label end
unclaimed_label(node; kw...) = unclaimed_label(node, PnmlCore(); kw...)
function unclaimed_label(node, pntd; kw...)::Pair{Symbol,PnmlDict}
    @assert haskey(kw, :reg)
    # ID attributes can appear in various places. Each is unique and added to the registry.
    #EzXML.haskey(node, "id") && register_id!(kw[:reg], node["id"])
    # Children may be claimed.
    return Symbol(nodename(node)) => _harvest_any!(node, pntd, _harvest_any!; kw...)
end

"""
$(TYPEDSIGNATURES)

Return `PnmlDict` holding a well-formed XML `node`.

If element `node` has any children, each is placed in the dictonary with the
child's tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value pairs.

Descend the well-formed XML using `parser` on child nodes.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hierarchy. And neither children nor content nor attribute may be present.
"""
function _harvest_any!(node::XMLNode, pntd::PNTD, parser; kw...) where {PNTD<:PnmlType}
    @assert haskey(kw, :reg)
    # Extract XML attributes. Register IDs as symbols.
    dict = PnmlDict()
    for a in eachattribute(node)
        dict[Symbol(a.name)] = a.name == "id" ? register_id!(kw[:reg], a.content) : a.content
    end

    # Extract children or content
    children = elements(node)
    if !isempty(children)
        merge!(dict, _anyelement_content(children, pntd, parser; kw...))
    elseif !isempty(nodecontent(node))
        # <tag> </tag> will have nodecontent, though the whitespace is discarded.
        dict[:content] = strip(nodecontent(node))
    else
        # <tag/> and <tag></tag> will not have any nodecontent.
        #TODO Force dict[:content] = "" ?
        #TODO <tag/> serves as a flag. (is key present?)
    end
    #@show dict
    return dict
end

"""
$(TYPEDSIGNATURES)

Apply `parser` to each node in `nodes`.
Return PnmlDict with values that are vectors when there 
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function _anyelement_content(nodes::Vector{XMLNode}, pntd::PNTD, parser; kw...) where {PNTD<:PnmlType}
    namevec = [nodename(node) => node for node in nodes] # Not yet turned into Symbols.
    tagnames = unique(map(first, namevec))
    dict = PnmlDict()
    foreach(tagnames) do tagname
        tags = filter(x->x.first===tagname, namevec)
        dict[Symbol(tagname)] = if length(tags) > 1 # Now its a symbol.
            parser.(map(x->x.second, tags), Ref(pntd), Ref(parser); kw...) # vector
        else
            parser(tags[1].second, pntd, parser; kw...) # scalar
        end
    end
    return dict
end

"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping `PnmlDict` holding a well-formed XML node.
See [`ToolInfo`](@ref) for a use-case. 
"""
function anyelement(node; kw...)::AnyElement
    @debug "anyelement = $(nodename(node))"
    d = _harvest_any!(node, anyelement; kw...)
    return AnyElement(d, node)
end

"""
$(TYPEDSIGNATURES)

Return `PnmlDict` holding pnml label.
"""
function unclaimed_label(node; kw...)::PnmlDict
    @debug "unclaimed = $(nodename(node))"
    @assert haskey(kw, :reg)
    # ID attributes can appear in various places. Each is unique and added to the registry.
    EzXML.haskey(node, "id") && register_id!(kw[:reg], node["id"])
    # Children may be claimed.
    return _harvest_any!(node, parse_node; kw...)
end

"""
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
"""
function _harvest_any!(node::XMLNode, parser; kw...)::PnmlDict
    # Extract XML attributes.
    dict = PnmlDict(:tag => Symbol(nodename(node)),
                 (Symbol(a.name) => a.content for a in eachattribute(node))...)
    # Extract children or content
    children = elements(node)
    if !isempty(children)
        merge!(dict, anyelement_content(children, parser; kw...))
    else
    if !isempty(nodecontent(node))
        dict[:content] = strip(nodecontent(node))
    end
    end
    return dict
end

"""
$(TYPEDSIGNATURES)

Return PnmlDict with values that are vectors when there 
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function anyelement_content(nodes::Vector{XMLNode}, parser; kw...)::PnmlDict
    d = PnmlDict()
    namevec = [nodename(node) => node for node in nodes] # Not yet turned into Symbols.
    tagnames = unique(map(first, namevec))
    foreach(tagnames) do tagname
        tags = filter(x->x.first===tagname, namevec)
        #TODO make toolspecific match annotation labels.declarations
        d[Symbol(tagname)] = if length(tags) > 1 # Now its a symbol.
            parser.(map(x->x.second, tags); kw...) #vector
        else
            parser(tags[1].second; kw...) #scalar
        end
    end
    return d
end

#=
"Update `dict` with content or children"
function _harvest!(dict::PnmlDict, node::XMLNode; kw...)::PnmlDict
    children = elements(node)
    if !isempty(children)
        merge!(dict, unclaimed_content(children; kw...))
    else
    if !isempty(nodecontent(node))
        dict[:content] = strip(nodecontent(node))
    end
    end
    return dict
end

"""
$(TYPEDSIGNATURES)

Return PnmlDict with values that are vectors when there 
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function unclaimed_content(nodes::Vector{XMLNode}; kw...)::PnmlDict
    d = PnmlDict()
    namevec = [nodename(node) => node for node in nodes] # Not yet turned into Symbols.
    tagnames = unique(map(first, namevec))
    foreach(tagnames) do tagname
        tags = filter(x->x.first===tagname, namevec)
        #TODO make toolspecific match annotation labels.declarations
        d[Symbol(tagname)] = if length(tags) > 1 # Now its a symbol.
            parse_node.(map(x->x.second, tags); kw...) #vector
        else
            parse_node(tags[1].second; kw...) #scalar
        end
    end
    return d
end
=#
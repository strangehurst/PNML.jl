"""
$(TYPEDSIGNATURES)

Return PnmlDict after debug print of nodename.
If element `node` has any children, each is placed in the dictonary with the
tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value. to the tuple returned.

Note that this will recursivly decend the well-formed XML.

Note the assumption that children and content are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hiearchy.

# Example
```jldoctest
julia> using PNML, EzXML

julia> node = parse_node(xml\"\"\"<aaa id=\"FOO\">BAR</aaa>\"\"\"; reg=PNML.IDRegistry());

```
"""
function attribute_elem(node; kwargs...)::PnmlDict
    @debug "attribute = $(nodename(node))"
    @assert haskey(kwargs, :reg)
    d = PnmlDict(:tag=>Symbol(nodename(node)),
                 (Symbol(a.name)=>((a.name == "id") ?
                                   register_id!(kwargs[:reg], a.content) :
                                   a.content) for a in eachattribute(node))...)
    e = elements(node)
    if !isempty(e)
        merge!(d, attribute_content(e; kwargs...)) # children elements
    else
        d[:content] = (!isempty(nodecontent(node)) ? strip(nodecontent(node)) : nothing)
    end
    d[:xml]=includexml(node)
    @debug d
    d
end

"""
$(TYPEDSIGNATURES)

Return PnmlDict with values that are vectors when there are multiple instances
of a tag in 'nv' and scalar otherwise.
"""
function attribute_content(nv::Vector{EzXML.Node}; kwargs...)
    d = PnmlDict()
    nn = [nodename(n)=>n for n in nv] # Not yet turned into Symbols.
    tagnames = unique(map(first,nn))
    foreach(tagnames) do tname 
        e = filter(x->x.first===tname, nn)
        #TODO make toolspecific match annotation labels.
        d[Symbol(tname)] = if length(e) > 1
            parse_node.(map(x->x.second, e); kwargs...)
        else
            parse_node(e[1].second; kwargs...)
        end
    end
    d
end


"""
$(TYPEDSIGNATURES)

Add `node` to` d[:labels]`. Return updated `d[:labels]`.
"""
function add_label!(d::PnmlDict, node; kwargs...)::Vector{PnmlDict}
    @debug "add label! $(nodename(node))"
    # Pnml considers any "unknown" element to be a label so its key is ':labels'.
    # The value is initialized to `nothing since it is expected that most labels
    # will have defined tags and semantics. And be given a key `:tag`.
    # Will convert value to a vector on first use.
    if d[:labels] === nothing
        d[:labels] = PnmlDict[] #TODO: pick type allowd in PnmlDict values? 
    end
    # Use of parse_node allows the :labels vector to contain fully parsed nodes.
    # Some higher-level might be able to make use of these.
    push!(d[:labels], parse_node(node; kwargs...))
end

"""
$(TYPEDSIGNATURES)

Add `node` to`d[:tools]`. Return updated `d[:tools]`.
"""
function add_tool!(d::PnmlDict, node; kwargs...)::Vector{PnmlDict}
    if d[:tools] === nothing
        d[:tools] = PnmlDict[] #TODO: pick type allowd in PnmlDict values? 
    end
    # Use of parse_node allows the :tools vector to contain fully parsed nodes.
    # Some higher-level might be able to make use of these.
    push!(d[:tools], parse_node(node; kwargs...))
end

"""
$(TYPEDSIGNATURES)

Return Dict of tags common to both pnml nodes and pnml labels.
See [`pnml_label_defaults`](@ref) and [`pnml_node_defaults`](@ref).
"""
function pnml_common_defaults(node)
    d = PnmlDict(:graphics=>nothing, # graphics tag is single despite the 's'.
                 :tools=>nothing, # Here the 's' indicates multiples are allowed.
                 :labels=>nothing,
                 :xml=>includexml(node))
    d
end

"""
$(TYPEDSIGNATURES)

Merge `xs` into dictonary with default pnml node tags.
Used on: net, page ,place, transition, arc.
Usually default value will be `nothing` or empty vector.
See [`pnml_label_defaults`](@ref) and [`pnml_common_defaults`](@ref).

"""
function pnml_node_defaults(node, xs...)
    #@show nodename(node)
    PnmlDict(pnml_common_defaults(node)...,
             :name=>nothing,
             xs...)
end

"""
$(TYPEDSIGNATURES)

Merge `xs` into dictonary with default pnml label tags.
Used on pnml tags below a pnml_node tag.
Label level tags include: name, inscription, initialMarking.
Notable differences from [`pnml_node_defaults`](@ref): text, structure, no name tag.
See [`pnml_common_defaults`](@ref).
"""
function pnml_label_defaults(node, xs...)::PnmlDict
    #@show nodename(node)
    PnmlDict(pnml_common_defaults(node)...,
             :text=>nothing,
             :structure=>nothing,
             xs...)
end


"""
$(TYPEDSIGNATURES)

Update `d` WITH graphics, tools, label children of pnml node and label elements.
Used by [`parse_pnml_node_common!`](@ref) & [`parse_pnml_label_common!`](@ref).
Adds, graphics, tools, labels.
Note that "lables" are the everything else option and this should be called after parsing
any elements that has an expected tags.
"""
function parse_pnml_common!(d::PnmlDict, node; kwargs...)
    @assert haskey(d, :graphics)
    @assert haskey(d, :tools)
    @assert haskey(d, :labels)

    @assert haskey(kwargs, :reg)
    @match nodename(node) begin
        "graphics"     => (d[:graphics] = parse_node(node; kwargs...))
        "toolspecific" => add_tool!(d, node; kwargs...)
        _ => add_label!(d, node; kwargs...) # label with a label allows any node to be attached & parsable.
    end
end

"""
$(TYPEDSIGNATURES)

Update `d` with `name` children, defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_node_common!(d::PnmlDict, node; kwargs...)
    @assert haskey(d, :name)    
    @assert haskey(kwargs, :reg)
    
    @match nodename(node) begin
        "name" => (d[:name] = parse_node(node; kwargs...))
        _      => parse_pnml_common!(d, node; kwargs...)
    end
end

"""
$(TYPEDSIGNATURES)

Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_label_common!(d::PnmlDict, node; kwargs...)
    @assert haskey(d, :text)
    @assert haskey(d, :structure)
    @assert haskey(kwargs, :reg)
    # Do not expect pnml labels to have names, so bark if one is found.
    !isempty(allchildren("name", node)) && @warn "label $(nodename(node)) has unexpected name"
    
    @match nodename(node) begin
        "text" => (d[:text] = parse_node(node; kwargs...)) #TODO label with name?
        "structure" => (d[:structure] = parse_node(node; kwargs...))
        _      => parse_pnml_common!(d, node; kwargs...)
    end
end


#TODO: A '<label>' tag could be hidden inside a '<structure>' tag.
"""
$(TYPEDSIGNATURES)

Should not often have a 'label' tag, this will bark if one is found.
Return minimal PnmlDict holding (tag,node), to defer parsing the xml.
"""
function parse_label(node; kwargs...)
    nn = nodename(node)
    nn == "label" || error("parse_label element name wrong: $nn")
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag=>Symbol(nn), :xml=>node) # Always add xml because this is unexpected.
end

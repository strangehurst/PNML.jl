"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping a `tag` symbol and `tuple` holding
a well-formed XML node. See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement end
anyelement(node::XMLNode, reg::PnmlIDRegistry) = anyelement(node, PnmlCoreNet(), reg)
function anyelement(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)::AnyElement
    AnyElement(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)

Return `tag` => `AnyXmlNode` holding well formed XML tree/forest.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref),
[`Term`](@ref) or other specialized label.
"""
function unclaimed_label(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    harvest! = HarvestAny(_harvest_any!, pntd, idregistry) # Create a functor.
    anyel = harvest!(node) # Apply functor.
    #println("unclaimed: "); dump(anyel)
    @assert length(anyel) >= 1 # Even empty elements have content.
    return Symbol(EzXML.nodename(node)) => anyel
end

text_content(l::PnmlLabel) = text_content(elements(l))
text_content(l::AnyElement) = text_content(elements(l))

text_content(vx::Vector{AnyXmlNode}) = begin
    tc = findfirst(x -> tag(x) === :text, vx)
    isnothing(tc) && throw(ArgumentError("missing <text>"))
    txt = value(vx[tc])
    #println("text"); dump(txt)

    tc = findfirst(x -> !isa(value(x), Number) && tag(x) === :content, txt)
    isnothing(tc) && throw(ArgumentError("missing text <content>"))
    #println("tc"); dump(tc)
    cnt = txt[tc]
    #println("content"); dump(cnt)
    val = value(cnt)
    #println("val"); dump(val)
    val isa AbstractString ||
        throw(ArgumentError("text content type '$(typeof(val))', expected <:AbstractString:\n$(dump(val))"))
    #println("text_content = ", val)
    return val
end
text_content(x::AnyXmlNode) = begin
    if tag(x) === :text || tag(x) === :content
        val = value(x)
        val isa AbstractString ||
            throw(ArgumentError(lazy"text content type '$(typeof(val))', expected <:AbstractString"))
        return val
    else
        @warn "missing text content" dump(x)
    end
end
text_content(s::AbstractString) = s

# Expected patterns. Note only first is standard-conforming, extensible, prefeered.
#   <tag><text>1.23</text><tag>
#   <tag>1.23<tag>
# The unclaimed label mechanism adds a :content key for text XML elements.
# When the text element is elided, there is still a :content.
function numeric_label_value(T, l::AnyXmlNode)
    number_value(T, text_content(l))
end



# Functor
"""
Wrap a function and two of its arguments.
"""
struct HarvestAny
    #!    fun::FunctionWrapper{NamedTuple, Tuple{XMLNode, HarvestAny}} #! returns unparamterized generic type
    fun::FunctionWrapper{Vector{AnyXmlNode}, Tuple{XMLNode, HarvestAny}} #! returns unparamterized generic type
    pntd::PnmlType # Maybe want to specialize sometime.
    reg::PnmlIDRegistry
end

(harvest!::HarvestAny)(node::XMLNode) = harvest!.fun(node, harvest!)

"Extract XML attributes. Register/convert IDs value as symbols."
function _attribute_value(a, harvest!)::Union{Symbol, String}
    a.name == "id" ? register_id!(harvest!.reg, a.content) : a.content
    #! Note type differs in legs: symbol and string
end

"""
$(TYPEDSIGNATURES)

Return `NamedTuple` holding a well-formed XML `node`.

If element `node` has any attributes &/or children, each is placed in the tuple using
attribute name or child's tag name symbol. Repeated tags produce a plain tuple as the value.
There will always be a `content` field in the returned tupel.

Descend the well-formed XML using parser function `harvest!` on child nodes.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hierarchy. And neither children nor content nor attribute may be present.
"""
function _harvest_any!(node::XMLNode, harvest!::HarvestAny)
    CONFIG.verbose && println("_harvest_any! ", EzXML.nodename(node))
    #tup = NamedTuple()
    vec = AnyXmlNode[]
    #
    #! Use consistent named tuple prototypes (tuple of symbols)?
    #! Is it worth the effort to avoid (howmuch?) dynamic dispatch in a parser?
    #! Once formed the objects better be type stable.

    for a in eachattribute(node)
        # ID attributes can appear in various places.
        #! See _attribute_value Each is unique, symbolized and added to the registry.
        #! ALL use unmodified content (some string) as the value.
        #tup = (; tup..., Symbol(a.name) => a.content) #_attribute_value(a, ha!)) #! ha! used for idregistry
        push!(vec, AnyXmlNode(Symbol(a.name), a.content))
    end

    if EzXML.haselement(node) # Children exist, extract them.
        _anyelement_content!(vec, node, harvest!)
    elseif isempty(vec) # Has attributes so does not get empty content.
        if !isempty(EzXML.nodecontent(node)) # <tag> </tag> will have nodecontent
            push!(vec, AnyXmlNode(:content, (strip ∘ EzXML.nodecontent)(node)))
        else # <tag/> and <tag></tag> will not have any nodecontent, give it an empty one.
            push!(vec, AnyXmlNode(:content, "")) #! :content might collide
        end
    end
    #CONFIG.verbose && println("anyelement fields ", propertynames(tup))
    return vec #! tup
end

"""
$(TYPEDSIGNATURES)

Apply `harvest!` to each child node of `node`.
Return named tuple where names are tags of children and values are tuples of namedtuples.
Refer to `AnyElement`, `PnmlLabel` for similar usage that pairs a tag with a single NamedTuple.

Example of a node that has repeated children elements:
<tag2>
    <child/>
    <child/>
</tag2>

Collectd by recursively applying `harvest!` as:
dictionary[tag2] == tuple(child1namedtuple, child2namedtuple)

Returnd as
NamedTuple(:tag2 => tuple(NamedTuple(:child1content => NamedTuple)), NamedTuple(:child2content => NamedTuple) )
"""
function _anyelement_content(node::XMLNode, harvest!::HarvestAny)
    dict = IdDict{Symbol, Tuple}()
    for n in EzXML.eachelement(node) #! iterate
        tag = Symbol(EzXML.nodename(n))
        content = harvest!(n) #! Recurse
        if !haskey(dict, tag)
            dict[tag] = tuple(content) # get/initialize collection for tag name
        else
            @inbounds dict[tag] = (dict[tag]..., content) #! accumulate duplicates, maintain order, DO NOT replace
        end
    end
    @assert !isempty(dict)
    return namedtuple(pairs(dict))
end
function _anyelement_content!(vec, node::XMLNode, harvest!::HarvestAny)
    for n in EzXML.eachelement(node) #! iterate
        push!(vec, AnyXmlNode(Symbol(EzXML.nodename(n)), harvest!(n))) #! Recurse
    end
    return nothing
end

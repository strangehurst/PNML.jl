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
function unclaimed_label(node::XMLNode, pntd::PnmlType, _::PnmlIDRegistry)
    harvest! = HarvestAny(_harvest_any!, pntd) # Create a functor.
    anyel = harvest!(node) # Apply functor.
    #println("unclaimed: "); dump(anyel)
    @assert length(anyel) >= 1 # Even empty elements have content.
    return Symbol(EzXML.nodename(node)) => anyel
end

"""
$(TYPEDSIGNATURES)
Find :text in AnyXmlNode[]
"""
function text_content end

text_content(l::PnmlLabel) = text_content(elements(l))
text_content(l::AnyElement) = text_content(elements(l))

text_content(vx::Vector{AnyXmlNode}) = begin
    tc = findfirst(x -> tag(x) === :text, vx)
    isnothing(tc) && throw(ArgumentError("missing <text>"))
    txt = value(vx[tc])
    tc = findfirst(x -> !isa(value(x), Number) && tag(x) === :content, txt)
    isnothing(tc) && throw(ArgumentError("missing <text> <content>"))
    cnt = txt[tc]
    val = value(cnt)
    val isa AbstractString ||
        throw(ArgumentError(lazy"""text content type '$(typeof(val))',
                                expected <:AbstractString:\n$(dump(val))"""))
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
    fun::FunctionWrapper{Vector{AnyXmlNode}, Tuple{XMLNode, HarvestAny}}
    pntd::PnmlType # Maybe want to specialize sometime.
end

(harvest!::HarvestAny)(node::XMLNode) = harvest!.fun(node, harvest!)

"""
$(TYPEDSIGNATURES)

Return `AnyXmlNode` vector holding a well-formed XML `node`.

If element `node` has any attributes &/or children, use
attribute name or child's name as tag.  (Empty is well-formed.)

Descend the well-formed XML using parser function `harvest!` on child nodes.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hierarchy. And neither children nor content nor attribute may be present.

Leaf `AnyXmlNode`'s contain an String or SubString.
"""
function _harvest_any!(node::XMLNode, harvest!::HarvestAny)
    CONFIG.verbose && println("harvest ", EzXML.nodename(node))

    vec = AnyXmlNode[]
    for a in EzXML.eachattribute(node)
        # Defer further :id attribute parsing by treating as a string here.
        push!(vec, AnyXmlNode(Symbol(a.name), a.content))
    end

    if EzXML.haselement(node) # Children exist, extract them.
        _anyelement_content!(vec, node, harvest!)
    else # No children, is there content?
        content_string = strip(EzXML.nodecontent(node))
        if !all(isspace, content_string) # Non-blank content after strip are leafs.
            push!(vec, AnyXmlNode(:content, content_string))
        elseif isempty(vec) # No need to make empty leaf.
            # <tag/> and <tag></tag> will not have any nodecontent.
            push!(vec, AnyXmlNode(:content, "")) #! :content might collide
        end
    end

    return vec
end

"""
$(TYPEDSIGNATURES)

Apply `harvest!` to each child node of `node`, appending to `vec`.
"""
function _anyelement_content!(vec, node::XMLNode, harvest!::HarvestAny)
    for n in EzXML.eachelement(node) #! iterate
        push!(vec, AnyXmlNode(Symbol(EzXML.nodename(n)), harvest!(n))) #! Recurse
    end
    return nothing
end

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

Return `tag` => `tuple` holding a pnml label and its children.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref),
[`Term`](@ref) or other specialized label.
"""
function unclaimed_label(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    ha! = HarvestAny(_harvest_any!, pntd, idregistry) # Create a functor.
    ucpair = Symbol(EzXML.nodename(node)) => ha!(node) # Apply functor.
    return  ucpair # Not type stable because of NamedTuples
end

text_content(l::PnmlLabel) = text_content(elements(l))
text_content(tup::NamedTuple) = begin
    if hasproperty(tup, :text)
        return tup.text[1].content
    elseif hasproperty(tup, :content)
        # Nonstandard fallback. Allows omitting text wapper (usually works?)?
        return tup.content
    else
        throw(ArgumentError("tag missing text content"))
    end
end

# Expected patterns. Note only first is standard-conforming, extensible, prefeered.
#   <tag><text>1.23</text><tag>
#   <tag>1.23<tag>
# The unclaimed label mechanism adds a :content key for text XML elements.
# When the text element is elided, there is still a :content.
function numeric_label_value(T, l)
    number_value(T, text_content(l))
end

# Functor
"""
Wrap a function and two of its arguments.
"""
struct HarvestAny
    fun::FunctionWrapper{NamedTuple, Tuple{XMLNode, HarvestAny}}
    pntd::PnmlType # Maybe want to specialize sometime.
    reg::PnmlIDRegistry
end

(ha!::HarvestAny)(node::XMLNode) = ha!.fun(node, ha!)

"Extract XML attributes. Register/convert IDs value as symbols."
_attribute_value(a, ha!) = a.name == "id" ? register_id!(ha!.reg, a.content) : a.content

"""
$(TYPEDSIGNATURES)

Return `NamedTuple` holding a well-formed XML `node`.

If element `node` has any attributes &/or children, each is placed in the tuple using
attribute name or child's tag name symbol. Repeated tags produce a plain tuple as the value.
There will always be a `content` field in the returned tupel.

Descend the well-formed XML using parser function `ha!` on child nodes.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hierarchy. And neither children nor content nor attribute may be present.
"""
function _harvest_any!(node::XMLNode, ha!::HarvestAny)
    CONFIG.verbose && println("harvest ", EzXML.nodename(node))
    tup = NamedTuple()

    #
    #! Use consistent named tuple prototypes (tuple of symbols)?
    #! Is it worth the effort to avoid (howmuch?) dynamic dispatch in a parser?
    #! Once formed the objects better be type stable.

    for a in eachattribute(node)
        # ID attributes can appear in various places.
        # Each is unique, symbolized and added to the registry.
        # Other names have unmodified content (some string) as the value.
        if a.name == "id"
            tup = (; tup..., Symbol(a.name) => register_id!(ha!.reg, a.content))
        else
            tup = (; tup..., Symbol(a.name) => a.content)
        end
    end

    if EzXML.haselement(node) # Children exist, extract them.
        tup = merge(tup, _anyelement_content(node, ha!)) #! iterate, returning named tuple
    elseif !isempty(EzXML.nodecontent(node)) # <tag> </tag> will have nodecontent, though the whitespace is discarded.
        tup = merge(tup, (; :content => (strip ∘ EzXML.nodecontent)(node)))
    else # <tag/> and <tag></tag> will not have any nodecontent, give it an empty one.
        tup = merge(tup, (; :content => ""))
    end

    #CONFIG.verbose &&
    #    println("anyelement fields ", propertynames(tup))
    return tup
end

"""
$(TYPEDSIGNATURES)

Apply `ha!` to each child node of `node`.
Return named tuple where names are tags and values are tuples.
"""
function _anyelement_content(node::XMLNode, ha!::HarvestAny)
    dict = Dict{Symbol,Any}()
    for n in EzXML.eachelement(node) #! iterate
        tag = Symbol(EzXML.nodename(n))
        tup = get(dict, tag, tuple()) # get/initialize tuple for tag name
        dict[tag] = tuple(tup..., ha!(n)) #! accumulate duplicates
    end
    @assert !isempty(dict)
    return namedtuple(pairs(dict))
end

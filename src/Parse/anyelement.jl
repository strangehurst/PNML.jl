"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)::AnyElement
    AnyElement(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)

Return `tag` => `AnyXmlNode` holding well formed XML tree/forest.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref),
[`Term`](@ref) or other.
"""
function unparsed_tag(node::XMLNode, pntd::PnmlType, _::Maybe{PnmlIDRegistry}=nothing)
    harvest! = HarvestAny(_harvest_any, pntd) # Create a functor.
    #println("harvest!: "); dump(harvest!); println()
    anyel = harvest!(node) # Apply functor.
    #println("unclaimed: "); dump(anyel)
    @assert length(anyel) >= 1 # Even empty elements have content.
    return Symbol(EzXML.nodename(node)) => anyel
end

# Expected patterns. Note only first is standard-conforming, extensible, preferred.
#   <tag><text>1.23</text><tag>
#   <tag>1.23<tag>
# The unclaimed label mechanism adds a :content key for text XML elements.

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
function _harvest_any(node::XMLNode, harvest!::HarvestAny)
    CONFIG.verbose && println("harvest ", EzXML.nodename(node))

    vec = AnyXmlNode[]
    for a in EzXML.eachattribute(node) # Leaf
        # Defer further :id attribute parsing/registering by treating as a string here.
        push!(vec, AnyXmlNode(Symbol(a.name), a.content))
    end

    if EzXML.haselement(node) # Children exist, extract them.
        for n in EzXML.eachelement(node)
            push!(vec, AnyXmlNode(Symbol(EzXML.nodename(n)), harvest!(n))) #! Recurse
        end
    else # No children, is there content?
        # Note: children and content are mutually exclusive because
        # `nodecontent` will include children's content.
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

#-----------------------------------------------------------------------------
# AnyXmlNode access methods.
#-----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
Find first :text in vx and return its :content as string.
"""
function text_content end

function text_content(vx::Vector{AnyXmlNode}) #TODO use nonallocating iteratable collection
    tc_index = findfirst(x -> tag(x) === :text, vx)
    isnothing(tc_index) && throw(ArgumentError("missing <text> element"))
    return text_content(vx[tc_index])
end

function text_content(axn::AnyXmlNode)
    #println("\ntext_content"); dump(axn)
    @assert tag(axn) === :text
    vals = value(axn)::Vector{AnyXmlNode} #TODO use nonallocating iteratable collection
    _attribute(vals, :content)
end

function _attribute(vx, tagid)
    _index = findfirst(x -> tag(x) === tagid, vx)
    isnothing(_index) && throw(ArgumentError("missing $tagid attribute"))
    val = value(vx[_index])
    val isa AbstractString ||
        throw(ArgumentError("wrong type, expected AbstractString got $(typeof(val))"))
    return val
 end

#=
Finite Enumeration Constants are id, name pairs
Array{PNML.AnyXmlNode}((2,))
  1: PNML.AnyXmlNode
    tag: Symbol id
    val: String "FE0"
  2: PNML.AnyXmlNode
    tag: Symbol name
    val: String "0"
=#
function id_name(vx::Vector{AnyXmlNode}) #TODO use nonallocating iteratable collection
    #println("id_name"); dump(vx)
    idval = _attribute(vx, :id)
    nameval = _attribute(vx, :name)
    return (Symbol(idval), nameval)
end

#=
finiteintrange sort:
Array{PNML.AnyXmlNode}((2,))
  1: PNML.AnyXmlNode
    tag: Symbol start
    val: String "2"
  2: PNML.AnyXmlNode
    tag: Symbol stop
    val: String "3"
=#
function start_stop(vx::Vector{AnyXmlNode}) #TODO use nonallocating iteratable collection
    startstr = _attribute(vx, :start)
    start = tryparse(Int, startstr)
    isnothing(start) && throw(ArgumentError("failed to parse as integer: $startstr"))

    stopstr = _attribute(vx, :stop)
    stop = tryparse(Int, stopstr)
    isnothing(stop) && throw(ArgumentError("failed to parse as integer: $stopstr"))
    return (start, stop)
end

#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(vx::Vector{AnyXmlNode}) #TODO use nonallocating iteratable collection
    #println("parse_partition"); dump(vx)

    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)

    sort_index = findfirst(x -> tag(x) === :usersort, vx)
    isnothing(sort_index) && throw(ArgumentError("missing partition sort"))
    sortv = value(vx[sort_index])::Vector
    sortdecl = parse_usersort(sortv)::AbstractString
    sortval = UserSort(sortdecl)

    elements = PartitionElement[]
    for pe in Iterators.filter(x -> tag(x) === :partitionelement, vx)
        e = parse_partitionelement(value(pe))
        push!(elements, e)
    end
    return (id = Symbol(idval), name = nameval, sort = sortval, elements = elements)
end

# one partitionelement = id, name, term[]
function parse_partitionelement(vx::Vector{AnyXmlNode})
    #println("parse_partitionelement"); dump(vx)
    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)
    # ordered collection of terms
    terms = UserOperator[]
    for t in Iterators.filter(x -> tag(x) === :useroperator, vx)
        v = value(t)
        v isa AbstractString || push!(terms, UserOperator(parse_decl(v)))
    end
    return PartitionElement(Symbol(idval), nameval, terms)
end
function parse_partitionelement(str::AbstractString)
    return PartitionElement()
end

"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)::AnyElement
    AnyElement(first(pairs(unparsed_tag(node, pntd, reg))))
end

"""
$(TYPEDSIGNATURES)

Return `DictType` holding well formed XML tree.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref), et al.
"""
function unparsed_tag(node::XMLNode, pntd::PnmlType, _::Maybe{PnmlIDRegistry}=nothing)
    anyel = XMLDict.xml_dict(node, DictType; strip_text=true)
    #!@show anyel #! debug
    @assert anyel isa Union{DictType, String, SubString}
    # empty dictionarys are a valid thing.
    @assert !(anyel isa DictType) || all(x -> !isnothing(x.second), pairs(anyel))
    #! Some things are tuples! as well as DistType, String, SubString
    return DictType(EzXML.nodename(node) => anyel)
end

# Expected patterns. Note only first is standard-conforming, extensible, preferred.
#   <tag><text>1.23</text><tag>
#   <tag>1.23<tag>
# The unclaimed label mechanism adds a :content key for text XML elements.

# # Functor
# """
# Wrap a function and two of its arguments.
# """
# struct HarvestAny
#     fun::FunctionWrapper{Vector{AnyXmlNode}, Tuple{XMLNode, HarvestAny}} #! will be abandoned
#     pntd::PnmlType # Maybe want to specialize sometime.
# end

# (harvest!::HarvestAny)(node::XMLNode) = harvest!.fun(node, harvest!)

# """
# $(TYPEDSIGNATURES)

# Return `AnyXmlNode` vector holding a well-formed XML `node`.  #! will be abandoned

# If element `node` has any attributes &/or children, use
# attribute name or child's name as tag.  (Empty is well-formed.)

# Descend the well-formed XML using parser function `harvest!` on child nodes.

# Note the assumption that "children" and "content" are mutually exclusive.
# Content is always a leaf element. However XML attributes can be anywhere in
# the hierarchy. And neither children nor content nor attribute may be present.

# Leaf `AnyXmlNode`'s contain an String or SubString.#! will be abandoned
# """
# function _harvest_any(node::XMLNode, harvest!::HarvestAny)
#     CONFIG.verbose && println("harvest ", EzXML.nodename(node))

#     vec = AnyXmlNode[] #! will be abandoned
#     for a in EzXML.eachattribute(node) # Leaf
#         # Defer further :id attribute parsing/registering by treating as a string here.
#         push!(vec, AnyXmlNode(Symbol(a.name), a.content)) #! will be abandoned
#     end

#     if EzXML.haselement(node) # Children exist, extract them.
#         for n in EzXML.eachelement(node)
#             push!(vec, AnyXmlNode(Symbol(EzXML.nodename(n)), harvest!(n))) #! Recurse #! will be abandoned
#         end
#     else # No children, is there content?
#         # Note: children and content are mutually exclusive because
#         # `nodecontent` will include children's content.
#         content_string = strip(EzXML.nodecontent(node))
#         if !all(isspace, content_string) # Non-blank content after strip are leafs.
#             push!(vec, AnyXmlNode(:content, content_string))#! will be abandoned
#         elseif isempty(vec) # No need to make empty leaf.
#             # <tag/> and <tag></tag> will not have any nodecontent.
#             push!(vec, AnyXmlNode(:content, "")) #! :content might collide#! will be abandoned
#         end
#     end

#     return vec
# end

#-----------------------------------------------------------------------------
# AnyXmlNode access methods. #! Replace with DictType
#-----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
Find first :text in vx and return its :content as string.
"""
function text_content end

function text_content(vx::DictType)
    haskey(vx, "text") && !isnothing(vx["text"]) && return vx["text"]
    throw(ArgumentError("missing <text> element in $(vx)"))
end
function text_content(s::AbstractString)
    return s
end

"""
Find an XML attribute. XMLDict uses symbols as keys.
"""
function _attribute(vx::DictType, key::Symbol)
    haskey(vx, key) || throw(ArgumentError("missing $key attribute"))
    isnothing(vx[key]) && throw(ArgumentError("missing $key value"))
    vx[key] isa AbstractString ||
        throw(ArgumentError("wrong type for attribute value, expected AbstractString got $(typeof(vx[key]))"))
    return vx[key]
 end

#=
Finite Enumeration Constants are id, name pairs
=#
function id_name(vx::DictType)
    idval = _attribute(vx, :id)
    nameval = _attribute(vx, :name)
    return (Symbol(idval), nameval)
end

#=
finiteintrange sort:
=#
function start_stop(vx::DictType)
    startstr = _attribute(vx, :start)
    start = tryparse(Int, startstr)
    isnothing(start) &&
        throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

    stopstr = _attribute(vx, :end) # XML Schema used 'end', we use 'stop'.
    stop = tryparse(Int, stopstr)
    isnothing(stop) &&
        throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))
    return (start, stop)
end

#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(vx::DictType)
    #println("parse_partition"); @show(vx)

    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)

    haskey(vx, "usersort") || throw(ArgumentError("<partition> missing <usersort> element"))
    us = vx["usersort"]
    @show us
    isnothing(us) && throw(ArgumentError("<partition> <usersort> element is nothing"))
    isempty(us)   && throw(ArgumentError("<partition> <usersort> element is empty"))
    sortdecl = parse_usersort(us)::AbstractString
    sortval = UserSort(sortdecl)
    @show sortval

    # One or more partitionelements.
    elements = PartitionElement[]

    haskey(vx, "partitionelement") || throw(ArgumentError("<partition> has no <partitionelement>"))
    pevec = vx["partitionelement"]
    @show pevec
    isnothing(pevec) && throw(ArgumentError("<partition> does not have any <partitionelement>"))

    parse_partitionelement!(elements, pevec)
    @assert !isempty(elements) """partitions are expected to have at least one partition element.
    id = idval, name = nameval, sort = sortval"""
    return (id = Symbol(idval), name = nameval, sort = sortval, elements = elements)
end

function parse_partitionelement!(elements::Vector{PartitionElement}, v::Vector{Any}) #!DictType})
    for pe in v
        parse_partitionelement!(elements, pe)
    end
    return nothing
end

# one partitionelement = id, name, term[]
#  OrderedDict{Union{String, Symbol}, Any}(:id => "bs1",
#                                           :name => "bs1",
#                                           "useroperator" => Any[OrderedDict{Union{String, Symbol}, Any}(:declaration => "b1"),
#                                                                 OrderedDict{Union{String, Symbol}, Any}(:declaration => "b2"),
#                                                                 OrderedDict{Union{String, Symbol}, Any}(:declaration => "b3")])

function parse_partitionelement!(elements::Vector{PartitionElement}, vx::DictType)
    println("parse_partitionelement!"); @show(vx)
    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)

    # ordered collection of terms, usually useroperators (as constants)
    haskey(vx, "useroperator") || throw(ArgumentError("<partitionelement> has no <useroperator> elements"))
    uovec = vx["useroperator"]
    isnothing(uovec) && throw(ArgumentError("<partitionelement> is empty"))
    @showln uovec
    terms = UserOperator[]
    parse_useroperators!(terms, uovec)
    @assert !isempty(terms)
    push!(elements, PartitionElement(Symbol(idval), nameval, terms))
    return nothing
end

function parse_useroperators!(terms::Vector{UserOperator}, vx::Vector{Any})
    for t in vx
        parse_useroperators!(terms, t)
    end
end

function parse_useroperators!(terms::Vector{UserOperator}, d::DictType)
    push!(terms, UserOperator(parse_decl(d)))
end

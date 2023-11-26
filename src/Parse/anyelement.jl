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
    isnothing(us) && throw(ArgumentError("<partition> <usersort> element is nothing"))
    isempty(us)   && throw(ArgumentError("<partition> <usersort> element is empty"))
    sortdecl = parse_usersort(us)::AbstractString
    sortval = UserSort(sortdecl)

    # One or more partitionelements.
    elements = PartitionElement[]

    haskey(vx, "partitionelement") || throw(ArgumentError("<partition> has no <partitionelement>"))
    pevec = vx["partitionelement"]
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

function parse_partitionelement!(elements::Vector{PartitionElement}, vx::DictType)
    #!println("parse_partitionelement!"); @show(vx)
    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)

    # ordered collection of terms, usually useroperators (as constants)
    haskey(vx, "useroperator") || throw(ArgumentError("<partitionelement> has no <useroperator> elements"))
    uovec = vx["useroperator"]
    isnothing(uovec) && throw(ArgumentError("<partitionelement> is empty"))
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

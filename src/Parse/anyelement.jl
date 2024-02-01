"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)::AnyElement
    AnyElement(unparsed_tag(node, pntd, reg)...)
end

"""
$(TYPEDSIGNATURES)

Return tuple of (tag, `XDVT`) holding well formed XML tree. `XMLDict`

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref), et al.
"""
function unparsed_tag(node::XMLNode, pntd::PnmlType, _::Maybe{PnmlIDRegistry}=nothing)
    tag = EzXML.nodename(node)
    xd::XDVT = XMLDict.xml_dict(node, OrderedDict{Union{Symbol, String}, Any}; strip_text=true)
    return (tag, xd) #return DictType(Pair{Union{Symbol,String}, XDVT}(tag, xd))
    # empty dictionarys are a valid thing.
end

#-----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
Find first :text in vx and return its :content as string.
"""
function text_content end

function text_content(vx::Vector{XDVT2})
    !isempty(vx) && text_content(first(vx))
    throw(ArgumentError("empty `Vector{XDVT}` not expected"))
end
function text_content(d::DictType)
    haskey(d, "text") && !isnothing(d["text"]) && return d["text"]
    throw(ArgumentError("missing <text> element in $(d)"))
end
text_content(s::String) = s
text_content(s::SubString{String}) = s

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
function parse_partition(vx::DictType, idregistry::PnmlIDRegistry)
    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)

    haskey(vx, "usersort") ||
        throw(ArgumentError("<partition id=$idval, name=$nameval> <usersort> element is missing"))
    us = vx["usersort"]
    isnothing(us) && throw(ArgumentError("<partition id=$idval, name=$nameval> <usersort> element is nothing"))
    isempty(us)   && throw(ArgumentError("<partition id=$idval, name=$nameval> <usersort> element is empty"))
    sortdecl = parse_usersort(us)::AbstractString
    sortval = UserSort(sortdecl)

    # One or more partitionelements.    elements = PartitionElement[]

    elements = PartitionElement[]

    haskey(vx, "partitionelement") ||
    throw(ArgumentError("<partition> has no <partitionelement>"))
    pevec = vx["partitionelement"]
    isnothing(pevec) &&
        throw(ArgumentError("<partition id=$idval, name=$nameval> does not have any <partitionelement>"))

    parse_partitionelement!(elements, pevec, idregistry)
    @assert !isempty(elements) """partitions are expected to have at least one partition element.
    id = idval, name = nameval, sort = sortval"""
    return PartitionSort(register_id!(idregistry, idval), nameval, sortval, elements)
end

function parse_partitionelement!(elements::Vector{PartitionElement}, v, idregistry::PnmlIDRegistry)
    for pe in v # any iteratable
        parse_partitionelement!(elements, pe, idregistry)
    end
    return nothing
end

function parse_partitionelement!(elements::Vector{PartitionElement},
                                vx::DictType, idregistry::PnmlIDRegistry)
    #println("parse_partitionelement! DictType")
    idval   = _attribute(vx, :id)
    nameval = _attribute(vx, :name)
    idsym = register_id!(idregistry, idval)
    # ordered collection of terms, usually useroperators (as constants)
    haskey(vx, "useroperator") ||
        throw(ArgumentError("<partitionelement id=$idval, name=$nameval> has no <useroperator> elements"))
    uovec = vx["useroperator"]
    isnothing(uovec) && throw(ArgumentError("<partitionelement id=$idval, name=$nameval> is empty"))
    terms = UserOperator[]
    parse_useroperators!(terms, uovec, idregistry)
    isempty(terms) && throw(ArgumentError("<partitionelement id=$idval, name=$nameval> has no terms"))

    push!(elements, PartitionElement(idsym, nameval, terms))
    return nothing
end

function parse_useroperators!(terms::Vector{UserOperator}, vx::Vector{Any}, idregistry::PnmlIDRegistry)
    for t in vx
        parse_useroperators!(terms, t, idregistry)
    end
end

function parse_useroperators!(terms::Vector{UserOperator}, d::DictType, idregistry::PnmlIDRegistry)
    #todo user operator waps the id symbol of a operator declaration
    push!(terms, UserOperator(parse_decl(d)))
end

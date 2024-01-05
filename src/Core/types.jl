# Core types and methods are documented in interfaces.jl.

"""
Alias for Union{`T`, `Nothing`}.
"""
const Maybe{T} = Union{T, Nothing}

#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type AbstractPnmlObject{PNTD<:PnmlType} end

# function Base.getproperty(o::AbstractPnmlObject, prop_name::Symbol)
#     prop_name === :id   && return getfield(o, :id)::Symbol
#     prop_name === :pntd && return getfield(o, :pntd)::PnmlType #! abstract
#     prop_name === :namelabel && return getfield(o, :namelabel)::Maybe{Name}

#     return getfield(o, prop_name)
# end

pid(o::AbstractPnmlObject)        = o.id

has_name(o::AbstractPnmlObject)   = hasproperty(o, :namelabel) && !isnothing(getfield(o, :namelabel))
name(o::AbstractPnmlObject)       = has_name(o) ? text(o.namelabel) : ""
name(::Nothing) = ""

has_labels(o::AbstractPnmlObject) = hasproperty(o, :labels) && !isnothing(o.labels)
labels(o::AbstractPnmlObject)     = o.labels

has_label(o::AbstractPnmlObject, tagvalue::Symbol) = has_label(labels(o), tagvalue)
get_label(o::AbstractPnmlObject, tagvalue::Symbol) = get_label(labels(o), tagvalue)

#
has_tools(o) = hasproperty(o, :tools) && !isempty(getfield(o, :tools))
tools(o)     = o.tools

has_graphics(o::AbstractPnmlObject) = hasproperty(o, :graphics) && !isnothing(o.graphics)
graphics(o::AbstractPnmlObject)     = o.graphics


#--------------------------------------------
"""
$(TYPEDEF)
Petri Net Graph nodes are [`Place`](@ref), [`Transition`](@ref).
They are the source or target of an [`Arc`](@ref)
"""
abstract type AbstractPnmlNode{PNTD} <: AbstractPnmlObject{PNTD} end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref)
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode{PNTD} <: AbstractPnmlNode{PNTD} end

function Base.getproperty(rn::ReferenceNode, name::Symbol)
    name === :ref && return getfield(rn, :ref)::Symbol
    return getfield(rn, name)
end

"Return the `id` of the referenced node."
refid(r::ReferenceNode) = r.ref

#------------------------------------------------------------------------------
# Abstract Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

#--------------------------------------------
"""
$(TYPEDEF)
Tool specific objects can be attached to
[`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

"OrderedDict filled by XMLDict"
const DictType = OrderedDict{Union{Symbol,String}, Any}

const XDVT2 = Union{DictType,  String,  SubString{String}}
const XDVT3 = Vector{XDVT2}
"XMLDict values type union. Maybe too large for union-splitting."
const XDVT = Union{XDVT2, XDVT3}

tag(d::DictType)   = first(keys(d)) # Expect only one key here, String or Symbol
value(d::DictType) = d[tag(d)]
value(s::Union{String, SubString{String}}) = s

function Base.show(io::IO, m::MIME"text/plain", d::DictType)
    show(io, d)
end
function Base.show(io::IO, d::DictType)
    dict_show(IOContext(io, :typeinfo => DictType), d)
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).

Creates a tree whose nodes are `Union{DictType, String, SubString{String}}`.
#TODO when can there be leaf nodes of String, Substying{String?}
See [`DictType`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol # XML tag
    elements::XDVT
end
#AnyElement(x::DictType) = AnyElement(first(pairs(x)))
#AnyElement(p::Pair{Union{String,Symbol}, Union{DictType, String, SubString{String}}}) = AnyElement(p.first, p.second)
#AnyElement(p::Pair) = AnyElement(p.first, p.second)
AnyElement(s::AbstractString, elems) = AnyElement(Symbol(s), elems)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements

function Base.show(io::IO, label::AnyElement)
    print(io, "AnyElement(")
    show(io, tag(label)); print(io, ", ")
    dict_show(io, elements(label), 0)
    print(io, ")")
end

"""
    dict_show(io::IO, x, 0()

Internal helper for things that contain `DictType`.
"""
function dict_show end


d_show(io::IO, x::Union{Vector,Tuple}, indent_by, before, after ) = begin
    print(io, before)
    for (i,e) in enumerate(x)
        dict_show(io, e, indent_by+8)
        i < length(x) && print(io, ", ")
    end
    print(io, after)
end

dict_show(io::IO, d::DictType, indent_by::Int=0 ) = begin
    print(io,"(")
    for (i,k) in enumerate(keys(d))
        print(io, "d[$(repr(k))] = ") #! Differs from `d_show` here.
        dict_show(io, d[k], indent_by+8) #! And here.
        i < length(keys(d)) && print(io, ", ")
    end
    print(io, ")")
end
dict_show(io::IO, v::Vector, indent_by::Int=0) = d_show(io, v, indent_by, '[', ']')
dict_show(io::IO, v::Tuple, indent_by::Int=0) =  d_show(io, v, indent_by, '(', ')')
dict_show(io::IO, s::SubString{String}, _::Int) = show(io, s)
dict_show(io::IO, s::AbstractString, _::Int) = show(io, s)
dict_show(io::IO, p::Pair, _::Int) = show(io, p)
dict_show(io::IO, p::Number, _::Int) = show(io, p)
dict_show(io::IO, x::Any, _::Int) = error("UNSUPPORTED dict_show(io, ::$(typeof(x)))")

#---------------------------------------------------------------------------
# Collect the Singleton to Type translations here.
# The part that needs to know Type details is defined elsewhere. :)
#---------------------------------------------------------------------------

pnmlnet_type(pntd::PnmlType)       = pnmlnet_type(typeof(pntd))
page_type(pntd::PnmlType)          = page_type(typeof(pntd))

place_type(pntd::PnmlType)         = place_type(typeof(pntd))
transition_type(pntd::PnmlType)    = transition_type(typeof(pntd))
arc_type(pntd::PnmlType)           = arc_type(typeof(pntd))
refplace_type(pntd::PnmlType)      = refplace_type(typeof(pntd))
reftransition_type(pntd::PnmlType) = reftransition_type(typeof(pntd))

marking_type(pntd::PnmlType)       = marking_type(typeof(pntd))
marking_value_type(pntd::PnmlType) = marking_value_type(typeof(pntd))

condition_type(pntd::PnmlType)       = condition_type(typeof(pntd))
condition_value_type(pntd::PnmlType) = condition_value_type(typeof(pntd))

inscription_type(pntd::PnmlType)       = inscription_type(typeof(pntd))
inscription_value_type(pntd::PnmlType) = inscription_value_type(typeof(pntd))

term_type(x::Any) = (throw ∘ ArgumentError)("no term_type defined for $(typeof(x))")
term_type(pntd::PnmlType)       = term_type(typeof(pntd))
term_value_type(pntd::PnmlType) = term_value_type(typeof(pntd))

coordinate_type(pntd::PnmlType)       = coordinate_type(typeof(pntd))
coordinate_value_type(pntd::PnmlType) = coordinate_value_type(typeof(pntd))

rate_value_type(pntd::PnmlType) = rate_value_type(typeof(pntd))
rate_value_type(::Type{<:PnmlType}) = Float64

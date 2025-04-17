# Core anyelement() XDVT
#--------------------------------------------
# Any Element
#--------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).

Creates a tree whose nodes are `Union{DictType, String, SubString{String}}`.
#TODO when can there be leaf nodes of String, SubString{String?}
See [`DictType`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol # XML tag
    elements::XDVT
end
AnyElement(s::AbstractString, elems) = AnyElement(Symbol(s), elems)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements # label elements

function Base.show(io::IO, label::AnyElement)
    print(io, "AnyElement(")
    show(io, tag(label)); print(io, ", ")
    dict_show(io, elements(label), 0)
    print(io, ")")
end

#--------------------------------------------
# Show Dict
#--------------------------------------------
"""
    dict_show(io::IO, x, 0)

Internal helper for things that contain `DictType`.
"""
function dict_show end

const increment::Int = 4

d_show(io::IO, x::Union{Vector,Tuple}, indent_by, before, after ) = begin
    print(io, before)
    for (i, e) in enumerate(x)
        dict_show(io, e, indent_by+increment) #
        i < length(x) && print(io, ",\n", indent(indent_by))
    end
    print(io, after)
end

dict_show(io::IO, d::DictType, indent_by::Int=0 ) = begin
    print(io, "(")
    for (i, k) in enumerate(pairs(d))
        print(io, "d[$(repr(k.first))] = ") #! Differs from `d_show` here.
        dict_show(io, k.second, indent_by+increment) #! And here.
        i < length(keys(d)) && print(io, ",\n", indent(indent_by))
    end
    print(io, ")")
end
dict_show(io::IO, v::Vector, indent_by::Int=0) = d_show(io, v, indent_by, '[', ']')
dict_show(io::IO, v::Tuple, indent_by::Int=0) =  d_show(io, v, indent_by, '(', ')')
dict_show(io::IO, s::SubString{String}, _::Int) = show(io, s)
dict_show(io::IO, s::AbstractString, _::Int) = show(io, s)
dict_show(io::IO, p::Pair, _::Int) = show(io, p)
dict_show(io::IO, p::Number, _::Int) = show(io, p)

#=
    Most things are symbol, DictType: AnyElement, PnmlLabel, Term, users of unparsed_tag.
    Note that Term also does Bool, Int, Float64, in addition to String.
    And that Term is (meant to be) Variable and Operator.

    This is the form of well-behaved XML: single rooted tree whose tag is the symbol.
    DictType is a collection of pairs: tag, value, where value may be a string/number or DictType.

    top-level tag symbol
    |   key is symbol or string
    |   |    value is dictionary, string, number
    |   |    |
    tag e1 = "string"!
        e2 = ee1 = tag2 x1 = vx1
                        x2 = vx2
                        x2 = vx2
                        x2 = vx2!
        e3 = 666!
        e4 = true!
        e5 = 3.14 #no ! here

    ! in newline
=#

function Base.show(io::IO, m::MIME"text/plain", d::DictType)
    show(io, d)
end
function Base.show(io::IO, d::DictType)
    dict_show(IOContext(io, :typeinfo => DictType), d)
end

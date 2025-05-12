#--------------------------------------------
# Any Element
#--------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).

Creates a tree where the leaf node values are `Union{String, SubString{String}}``, and
interior nodes values are `Union{DictType, Vector{DictType}}`

See [`DictType`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol # XML tag
    elements::Any # XDVT is too complex
end
AnyElement(s::AbstractString, elems) = AnyElement(Symbol(s), elems)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements # label elements

function Base.show(io::IO, ae::AnyElement)
    print(io, "AnyElement(")
    show(io, tag(ae)); print(io, ", ")
    dict_show(io, elements(ae))
    print(io, ")")
end
function Base.show(io::IO, vae::Vector{AnyElement})
    print(io, "AnyElement[")
    io = inc_indent(io)  # one more indent
    foreach(vae) do ae
        print(io, indent(io));
        dict_show(io, elements(ae))
    end
    print(io, "]")
end

#--------------------------------------------
# Show Dict
#--------------------------------------------
"""
    dict_show(io::IO, x)

Internal helper for things that contain `DictType`.
"""
function dict_show end


d_show(io::IO, x::Union{Vector,Tuple}, before, after ) = begin
    print(io, before)
    for (i, e) in enumerate(x)
        iio = inc_indent(io)
        #! dict_show prints `first` here
        dict_show(iio, e) #! this is `second`.
        i < length(x) && print(io, ",\n", indent(io))
    end
    print(io, after)
end

dict_show(io::IO, d::DictType) = begin
    print(io, "(")
    for (i, k) in enumerate(pairs(d))
        iio = inc_indent(io)
        print(io, "d[$(repr(k.first))] = ") #! Differs from `d_show` here.
        dict_show(iio, k.second)            #! And here.
        i < length(keys(d)) && print(io, ",\n", indent(io))
    end
    print(io, ")")
end

dict_show(io::IO, v::Vector) = d_show(io, v, '[', ']')
dict_show(io::IO, v::Tuple) =  d_show(io, v, '(', ')')
dict_show(io::IO, s::SubString{String}) = show(io, s)
dict_show(io::IO, s::AbstractString) = show(io, s)
dict_show(io::IO, p::Pair) = show(io, p)
dict_show(io::IO, p::Number) = show(io, p)

#=
    Most things are symbol, DictType: AnyElement, PnmlLabel, Term, users of unparsed_tag.

    This is the form of well-behaved XML: forest of single rooted tree whose tag is the symbol.

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

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
    # XMLDict uses symbols for attribute keys and string for elements/children keys.
    tag::Union{Symbol, String, SubString{String}}
    elements::Any # Value of attribute or content of child
end

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements # label elements

function Base.show(io::IO, ae::AnyElement)
    print(io, "AnyElement(", tag(ae), ", ")
    dict_show(io, elements(ae))
    print(io, ")")
end

function Base.show(io::IO, vae::Vector{AnyElement})
    print(io, "AnyElement[")
    io = inc_indent(io)  # one more indent
    for (i, ae) in enumerate(vae)
        show(io, ae)
        i < length(vae) && print(io, ",\n", indent(io))
    end
    println(io, "]")
end

#--------------------------------------------
# Show Dict
#--------------------------------------------
"""
    dict_show(io::IO, x)

Internal helper for things that contain `DictType`.
"""
function dict_show end

"Alternate to dict_show. Prints `before`, `after`"
_d_show(io::IO, x::Union{Vector,Tuple}, before, after ) = begin
    print(io, before)
    iio = inc_indent(io)
    for (i, e) in enumerate(x)
        #! dict_show prints the key here, but vector, tuple do not have keys.
        i > 1 && print(io, "\n", indent(io))
        dict_show(iio, e) #! this is the value.
        i < length(keys(x)) && print(io, ",")
        #i < length(x) && print(io, ",\n", indent(io))
    end
    println(io, after)
end

dict_show(io::IO, d::DictType) = begin
    print(io, "(") # before
    iio = inc_indent(io)
    for (i, kv) in enumerate(pairs(d))
        i > 1 && print(io, "\n", indent(io))
        print(io, "d[$(repr(kv.first))] = ") #! Differs from `_d_show` here.
        dict_show(iio, kv.second)            #! And here.
        i < length(keys(d)) && print(io, ",")
        #i < length(keys(d)) && print(io, ",\n", indent(io))
    end
    print(io, ")") # after
end

dict_show(io::IO, v::Vector) = _d_show(io, v, '[', ']')
dict_show(io::IO, v::Tuple) =  _d_show(io, v, '(', ')')
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

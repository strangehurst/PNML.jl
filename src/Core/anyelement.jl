#--------------------------------------------
# AnyElement and DictType
#--------------------------------------------

"Dictionary passed to `XMLDict.xml_dict` as `dict_type`. See `xmldict`."
const DictType = LittleDict{Union{Symbol,String}, Any #= XDVT is a complex Union =#}

"`XMLDict.xml_dict` XMLDict Value Type is value or Vector of values from ."
const XDVT = Union{DictType, String, SubString, Vector{Union{DictType,String,SubString}}}

tag(d::DictType) = first(keys(d)) # String or Symbol

"""
$(TYPEDSIGNATURES)
Find first :text and return its :content as string.
"""
function text_content end

function text_content(vx::Vector{Any})
    isempty(vx) && throw(ArgumentError("empty `Vector` not expected"))
    text_content(first(vx))
end

function text_content(d::DictType)
    x = get(d, "text", nothing)
    isnothing(x) && throw(ArgumentError("missing <text> element in $(d)"))
    return x
end
text_content(s::Union{String,SubString{String}}) = s

"""
XMLDict uses symbols as keys. Value returned is a string.
"""
function _attribute(vx::DictType, key::Symbol)
    x = get(vx, key, nothing)
    isnothing(x) && throw(ArgumentError("missing $key value"))
    isa(x, AbstractString) ||
        throw(ArgumentError("expected AbstractString got $(typeof(vx[key]))"))
    return x
end

#-------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).

Creates a tree where the root is `tag`,
leaf node values are `Union{String, SubString{String}}`, and
interior nodes values are `Union{DictType, Vector{DictType}}`

See [`DictType`](@ref).
"""
@auto_hash_equals struct AnyElement
    # XMLDict uses symbols for attribute keys and string for elements/children keys.
    tag::Union{Symbol, String, SubString{String}}
    elements::Union{DictType, String, SubString{String}} # is Any better?
end

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements # label elements

function Base.show(io::IO, vae::Vector{AnyElement})
    println(io, "AnyElement[")
    iio = inc_indent(io)  # one more indent
    for (i, ae) in enumerate(vae)
        i > 1 && print(iio, indent(iio))
        show(iio, ae)
        length(vae) > 1 && i < length(vae) && println(iio)
    end
    println(io, "]")
end

function Base.show(io::IO, ae::AnyElement)
    print(io, "AnyElement(", repr(tag(ae)), ", ")
    #length(elements(ae))  > 1 && println(io)
    dict_show(inc_indent(io), elements(ae)) # what XMLDict produced
    print(io, ")")
end

#--------------------------------------------
# Show Dict
#--------------------------------------------
"""
    dict_show(io::IO, x)

Internal helper for things that contain `DictType`.
"""
function dict_show end

# Called by show AnyElement
dict_show(io::IO, d::DictType) = begin
    iio = inc_indent(io)
    for (i, kv) in enumerate(pairs(d))
        i > 1 && print(iio, indent(iio))
        print(iio, "d[$(repr(kv.first))] = ") #! Differs from `_d_show` here.
        dict_show(iio, kv.second)            #! And here.
        length(keys(d)) > 1 && i < length(keys(d)) && println(io)
    end
    #print(io, ")") # after
end

dict_show(io::IO, s::SubString{String}) = show(io, s)
dict_show(io::IO, s::AbstractString)    = show(io, s)
dict_show(io::IO, p::Pair)   = show(io, p)
dict_show(io::IO, p::Number) = show(io, p)
dict_show(io::IO, p::Nothing) = print(io, repr(p))

function Base.show(io::IO, ::MIME"text/plain", d::DictType)
    show(io, d)
end
function Base.show(io::IO, d::DictType)
    dict_show(IOContext(io, :typeinfo => DictType), d)
end

#--------------------------------------------
# AnyElement and DictType
#--------------------------------------------

"Dictionary passed to `XMLDict.xml_dict` as `dict_type`. See `xmldict`."
const DictType = LittleDict{Union{Symbol,String}, Any}

"""
    XMLDict Value Type, what `XMLDict.xml_dict` returns.
    Note that there may be Arrays holding repeated tags's values in the dictionary.
"""
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

Hold AbstractDict holding zero or more well-formed XML elments.
See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).

Creates a tree where the root is `tag`,
leaf node values are `Union{String, SubString{String}}`, and
interior nodes values are `Union{DictType, Vector{DictType}}`

See [`DictType`](@ref).
"""
@auto_hash_equals struct AnyElement
    # Tag of node enclosing the
    tag::Symbol
    # LittleDict{Union{Symbol,String}, Any}  returned by `xmldict`.
    # We hope/promise the following is the Type of ALL values in dictionary.
    elements::LittleDict{Union{Symbol,String},
                         Union{DictType, String, SubString{String}, Vector{Any}}}
end

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements # label elements

# function Base.show(io::IO, vae::Vector{AnyElement}) #! styleguide says don't do this!
#     println(io, "AnyElement[")
#     iio = inc_indent(io)  # one more indent
#     for (i, ae) in enumerate(vae)
#         i > 1 && print(iio, indent(iio))
#         show(iio, ae)
#         length(vae) > 1 && i < length(vae) && println(iio)
#     end
#     println(io, "]")
# end

function Base.show(io::IO, ae::AnyElement)
    print(io, "AnyElement(", repr(tag(ae)), ", ")
    print(inc_indent(io), elements(ae)) # what XMLDict produced
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
function dict_show(io::IO, d::DictType)
    iio = inc_indent(io)
    for (i, kv) in enumerate(pairs(d))
        i > 1 && print(iio, indent(iio))
        print(iio, "d[$(repr(kv.first))] = ")
        dict_show(iio, kv.second)
        length(keys(d)) > 1 && i < length(keys(d)) && println(io)
    end
end

function dict_show(io::IO, d::Vector)
    iio = inc_indent(io)
    print(iio, "[")
    for (i,el) in enumerate(d)
        dict_show(iio, el)
        length(keys(d)) > 1 && i < length(keys(d)) && print(iio, ", ")
    end
    print(iio, "]")
end

dict_show(io::IO, s::SubString{String}) = show(io, s)
dict_show(io::IO, s::AbstractString)    = show(io, s)
# dict_show(io::IO, p::Pair)   = show(io, p)
# dict_show(io::IO, p::Number) = show(io, p)
# dict_show(io::IO, p::Nothing) = print(io, repr(p))

function Base.show(io::IO, ::MIME"text/plain", d::DictType)
    show(io, d)
end

function Base.show(io::IO, d::DictType)
    dict_show(io, d)
end

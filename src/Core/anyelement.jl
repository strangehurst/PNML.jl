#--------------------------------------------
# AnyElement and DictType
#--------------------------------------------

#--------------------------------------------
# """
# $(TYPEDEF)
# Tool specific information objects can be attached to nodes and labels,
# [`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
# """
# abstract type AbstractPnmlTool end #TODO see ToolInfo

#=      XMLDict notes

mutable struct XMLDictElement <: AbstractDict{Union{String,Symbol},Any}

DictType is used for xml_dict's dict_type argument.


r = dict_type()
attribute a:  r[Symbol(nodename(a))] = nodecontent(a) #! Symbol key, String value (SubString?)

# The empty-string key holds a vector of sub-elements.
# This is necessary when grouping sub-elements would alter ordering...

for c in eachnode(x)
    if iselement(c)
        n = nodename(c) #! String, SubString as key
        v = xml_dict(c, dict_type; strip_text=strip_text)
        if haskey(r, "")
            push!(r[""], dict_type(n => v)) #! Vector of dicts and strings as value
        elseif haskey(r, n)
            a = isa(r[n], Array) ? r[n] : Any[r[n]] #! turn scalar into vector
            push!(a, v)
            r[n] = a #! Vector value
        else
            r[n] = v #! dict value
        end
    elseif is_text(c) && haskey(r, "")
        push!(r[""], nodecontent(c)) #! String value
    end
end
# Collapse leaf-node vectors containing only text...
if haskey(r, "")
    v = r[""]
    if length(v) == 1 && isa(v[1], AbstractString)
        if strip_text
            v[1] = strip(v[1])
        end
        r[""] = v[1]

        # If "r" contains no other keys, collapse the "" key...
        if length(r) == 1
            r = r[""]
        end
    end

end
values: DictType, String, SubString, Vector{Union{DictType, String, SubString}}
=#


"Dictionary passed to `XMLDict.xml_dict` as `dict_type`. See `unparsed_tag`."
const DictType = LittleDict{Union{Symbol,String}, Any #= XDVT =#}

"XMLDict Value Type is value or Vector of values from `XMLDict.xml_dict`."
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
    println(io, "AnyElement(", repr(tag(ae)), ", ")
    dict_show(inc_indent(io), elements(ae))
    print(io, ")")
end

function Base.show(io::IO, vae::Vector{AnyElement})
    println(io, "AnyElement[")
    iio = inc_indent(io)  # one more indent
    for (i, ae) in enumerate(vae)
        indent(iio); show(iio, ae)
        i < length(vae) && print(iio, ",\n")
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

"Alternate to dict_show. Prints `before`, `after` with ordered collection between"
_d_show(io::IO, x::Union{Vector,Tuple}, before, after ) = begin
    println("_d_show")
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

# Called by show AnyElement
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

function Base.show(io::IO, ::MIME"text/plain", d::DictType)
    show(io, d)
end
function Base.show(io::IO, d::DictType)
    println("show DictType")
    dict_show(IOContext(io, :typeinfo => DictType), d)
end

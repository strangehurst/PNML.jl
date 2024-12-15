# "Return first true `f` of `v` or `nothing`."
# function getfirst(f, v)
#     i = findfirst(f, v) # Cannot use nothing as an index/key.
#     isnothing(i) ? nothing : v[i]
# end


# Since PNML is based on integer numbers and booleans it seems reasonable to use `Number`,
# which includes `Bool` and `Real`.
toexpr(x::Number, ::Any) = identity(x) #! literal


"""
    ispid(x::Symbol)

Return function to be used like: any(ispid(:asym), iterable_with_pid).
"""
ispid(x::Symbol) = Fix2(===, x)

# "Extract pnml network ID from trail of symbols"
# netid(x::Tuple) = first(x)
# netid(x::Any) = hasproperty(x, :ids) ? first(x.ids) : error("$(typeof(x)) missing ids")



"Return blank string of current indent size in `io`."
indent(io::IO) = indent(get(io, :indent, 0)::Int)
indent(i::Int) = repeat(' ', i)

"Increment the `:indent` value by `inc`."
inc_indent(io::IO, inc::Int=CONFIG[].indent_width) =
        IOContext(io, :indent => get(io, :indent, 0)::Int + inc)

"""
    number_value(::Type{T}, s) -> T

Parse string as a type T <: Number.
"""
function number_value(::Type{T}, s::AbstractString)::T where {T <: Number}
    x = tryparse(T, s)
    isnothing(x) && throw(ArgumentError(lazy"cannot parse '$s' as $T"))
    return x
end

toexpr(::Nothing, ::Any) = nothing


"""
    ispid(x::Symbol)

Return function to be used like: any(ispid(:asym), iterable_with_pid).
"""
ispid(x::Symbol) = Fix2(===, x)

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

toexpr(::Nothing, ::NamedTuple) = nothing
toexpr(x::Number, ::NamedTuple) = identity(x) #! literal
toexpr(s::Symbol, ::NamedTuple) = QuoteNode(s)
toexpr(t::Tuple, vsub::NamedTuple) = begin
    # @error "toexpr(t::Tuple, vsub::NamedTuple)" t vsub
    return t
end

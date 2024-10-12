# "Return first true `f` of `v` or `nothing`."
# function getfirst(f, v)
#     i = findfirst(f, v) # Cannot use nothing as an index/key.
#     isnothing(i) ? nothing : v[i]
# end

"""
    _evaluate(x::Number) -> identity(x)
    _evaluate(x::Base.Callable) -> (x)()

Return the value of "x", defaults to identity.

# Examples

Since High-level PNML schemas are based on zero, Natural numbers and booleans,
it seems reasonable to assume `Number`, which includes `Bool`, for the non-callable type.
Especially as it allows negative numbers and reals.
A zero-argument functor is expected as the callable type, allowing expressions in the many-sorted algebra
to be evaluated to a `Number`.
"""
function _evaluate end
_evaluate(x::Number) = begin println("_evaluate Number $(nameof(typeof(x)))"); identity(x); end #! dynamic term rewrite
#! _evaluate(x::Base.Callable) = begin println("_evaluate call $(nameof(typeof(x)))"); (x)(); end #! dynamic term rewrite

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
    isnothing(x) && throw(ArgumentError("cannot parse '$s' as $T"))
    return x
end

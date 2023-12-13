"Return first true `f` of `v` or `nothing`."
function getfirst(f, v) # getfirst(f::F, v) where {F}
    i = findfirst(f, v) # Cannot use nothing as an index.
    isnothing(i) ? nothing : v[i]
end

"""
    _evaluate(x::Number) -> identity(x)
    _evaluate(x::Base.Callable) -> (x)()

Return the value of "x", defaults to identity.

# Examples

Since High-level PNML schemas are based on Natural numbers and booleans,
it seems reasonable to assume `Number`, which includes `Bool`, for the non-callable type.
A functor is expected as the callable type, allowing expressions in the many-sorted algebra
to be evaluated to a `Number`.
"""
function _evaluate end
_evaluate(x::Number) = identity(x)
_evaluate(x::Base.Callable) = (x)()

"""
    ispid(x::Symbol)

Return function to be used like: any(ispid(:asym), iterable_with_pid).
"""
ispid(x::Symbol) = Fix2(===, x)
haspid(x, id::Symbol) = ispid(id)(x) #!pid(x) === id
haspid(s::Any) = throw(ArgumentError("haspid used on $(typeof(s)) $s, do you want `ispid`"))

"Return blank string of current indent size in `io`."
indent(io::IO) = indent(get(io, :indent, 0)::Int)
indent(i::Int) = repeat(' ', i)

"Increment the `:indent` value by `inc`."
inc_indent(io::IO, inc::Int=CONFIG.indent_width) =
        IOContext(io, :indent => get(io, :indent, 0)::Int + inc)

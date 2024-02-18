"Return first true `f` of `v` or `nothing`."
function getfirst(f, v)
    i = findfirst(f, v) # Cannot use nothing as an index/key.
    isnothing(i) ? nothing : v[i]
end

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
_evaluate(x::Number) = identity(x)
_evaluate(x::Base.Callable) = (x)()

"""
    ispid(x::Symbol)

Return function to be used like: any(ispid(:asym), iterable_with_pid).
"""
ispid(x::Symbol) = Fix2(===, x)

"Return blank string of current indent size in `io`."
indent(io::IO) = indent(get(io, :indent, 0)::Int)
indent(i::Int) = repeat(' ', i)

"Increment the `:indent` value by `inc`."
inc_indent(io::IO, inc::Int=CONFIG.indent_width) =
        IOContext(io, :indent => get(io, :indent, 0)::Int + inc)

"""
registry([lock]) -> PnmlIDRegistry

Construct a PNML ID registry using the supplied AbstractLock or nothing to not lock.
"""
function registry(lock = CONFIG.lock_registry ? ReentrantLock() : nothing)
    # isnothing(lock) || println("using lock $lock")
    PnmlIDRegistry(Set{Symbol}(), lock)
end

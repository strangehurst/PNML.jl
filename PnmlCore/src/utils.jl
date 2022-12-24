"Return first true `f` of `v` or `nothing`."
function getfirst(f::Function, v)
    i = findfirst(f, v) # Cannot use nothing as an index.
    isnothing(i) ? nothing : v[i]
end


"""
$(TYPEDSIGNATURES)
Some objects evaluate a value that may be simple or a functor.
"""
function _evaluate end
_evaluate(x::Any) = x # identity

"""
$(TYPEDSIGNATURES)
Return function to be used like: any(ispid(sym), iterate_with_pid)
"""
ispid(x::Symbol) = Fix2(===, x)
haspid(x, id::Symbol) = pid(x) === id
haspid(s::Any) = throw(ArgumentError("haspid used on $(typeof(s)) $s, do you want `ispid`"))


"Indention increment."
const indent_width = @load_preference("indent_width", 4)

"Return string of current indent size in `io`."
indent(io::IO) = repeat(' ', get(io, :indent, 0))

"Increment the `:indent` value by `indent_width`."
inc_indent(io::IO) = IOContext(io, :indent => get(io, :indent, 0) + indent_width)

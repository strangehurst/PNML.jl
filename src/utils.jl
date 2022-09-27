"Return first true `f` of `v` or `nothing`."
function getfirst(f::Function, v)
    i = findfirst(f,v) # Cannot use nothing as an index.
    isnothing(i) ? nothing : v[i]
end

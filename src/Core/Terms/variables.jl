"""
$(TYPEDEF)
$(TYPEDFIELDS)
Bool, Int, Float64, XDVT
Variable refers to a varaible declaration.
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractTerm
    variableDecl::Symbol
    ids::Tuple # For DeclDict lookups.
end
tag(v::Variable) = v.variableDecl
netid(v::Variable) = first(v.ids)
function (var::Variable)()
    _evaluate(var)
end
value(v::Variable) = begin
    println("value(::Variable) $(tag(v)) in $(netid(v)) needs access to DeclDict")
    dd = decldict(netid(v))
    @assert has_variable(dd, tag(v)) "$(tag(v)) not a variable declaration in $(netid(v))"
    @show variable(dd, tag(v))
    return 0 #! XXX FIXME XXX
end
_evaluate(v::Variable) = _evaluate(value(v))

sortof(v::Variable) = begin
    #println("sortof(::Variable) $(tag(v)) in $(netid(v)) needs access to DeclDict")
    #display(stacktrace())
    dd = decldict(netid(v))
    @assert has_variable(dd, tag(v)) "$(tag(v)) not a variable declaration in $(netid(v))"
    vdecl = variable(dd, tag(v))
    return sortof(vdecl)
end

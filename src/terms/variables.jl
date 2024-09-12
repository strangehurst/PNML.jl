"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractVariable
    refvariable::Symbol
end
tag(v::Variable) = v.refvariable

function (var::Variable)()
    _evaluate(var)
end
value(v::Variable) = begin #! XXX FIXME XXX
    @assert has_variable(tag(v)) "$(tag(v)) not a variable declaration"
    return 0
end
_evaluate(v::Variable) = begin println("_evaluate: variable"); _evaluate(value(v)); end #! dynamic expression, term rewrite, firing rule

sortof(v::Variable) = begin
    @assert has_variable(tag(v)) "$(tag(v)) not a variable declaration"
    vdecl = variable(tag(v))
    return sortof(vdecl)
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

# Only One
isvariable(tag::Symbol) = tag === :variable

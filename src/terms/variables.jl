"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a [`VariableDeclaration`](@ref).
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractVariable
    refvariable::REFID
    function Variable(v::REFID)
        # Check that REFID is valid in DECLDICT[].
        PNML.has_variabledecl(v) || throw(ArgumentError("$(v) not a variable reference ID"))
        new(v)
    end
end

refid(v::Variable) = v.refvariable

function (var::Variable)()
    value(var)
end
value(v::Variable) = error("not well defined: value($v)") #! XXX FIXME XXX

sortref(v::Variable) = sortref(variable(refid(v)))::UserSort # Access variabledecl in decldicts
sortof(v::Variable)  = sortof(variable(refid(v)))  # Access variabledecl in decldicts

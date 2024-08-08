# boolean sort operators

"""
    BooleanConstant("true"|"false")
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
end

function BooleanConstant(s::Union{AbstractString,SubString{String}})
    s == "true" || s == "false" || throw(ArgumentError("BooleanConstant unexpected value $s"))
    BooleanConstant(parse(eltype(BoolSort), s))
end
tag(::BooleanConstant) = :booleanconstant
sortof(::BooleanConstant) = sortof(usersort(:bool))

(c::BooleanConstant)() = value(c)
value(bc::BooleanConstant) = _evaluate(bc)
_evaluate(bc::BooleanConstant) = bc.value

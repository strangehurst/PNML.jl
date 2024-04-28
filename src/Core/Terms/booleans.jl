# boolean sort operators

"""
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
end

function BooleanConstant(s::Union{AbstractString,SubString{String}})
    s == "true" || s == "false" || throw(ArgumentError("BooleanConstant unexpected value $s"))
    BooleanConstant(parse(eltype(BoolSort), s))
end
tag(::BooleanConstant) = :booleanconstant
sortof(::BooleanConstant) = BoolSort()
value(bc::BooleanConstant) = _evaluate(bc)
_evaluate(bc::BooleanConstant) = bc.value
(c::BooleanConstant)() = value(c)

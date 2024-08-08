"""
    FEConstant

Finite enumeration constant.

# Usage
    fec = FEConstant(:anID, asort, "somevalue")
    fec() == "somevalue"
"""
struct FEConstant <: OperatorDeclaration
    id::Symbol # ID is unique within net.
    #TODO add reference to the owning sort?
    #!sortid::Symbol # REFID of named sort that contains this constant (0-arity operator)
    name::Union{String, SubString{String}} # Must name be unique within a sort?
end

sortof(fec::FEConstant) = sortof(namedsort(fec.sortid)) # we omit the usersort.

(fec::FEConstant)() = fec.name # The value of a FEConstant is its name/identity. Not a `<:Number`.

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "(", repr(pid(fec)), ", ", #=repr(fec.sortid), ", ",=# repr(fec()), ")")
end



#TODO Which to do: functor or expression?
#~ functor is an atom
TermInterface.isexpr(op::FEConstant)    = false
TermInterface.iscall(op::FEConstant)    = false # users promise that this is only called if isexpr is true.
TermInterface.head(op::FEConstant)      = :ref
TermInterface.children(op::FEConstant)  = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.operation(op::FEConstant) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arguments(op::FEConstant) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arity(op::FEConstant)     = 0
TermInterface.metadata(op::FEConstant)  = error("NOT IMPLEMENTED: $(typeof(op))")

"""
    FEConstant
Finite enumeration constant.
In some cases the partition element cannot be derived from the subterms of PartitionElementOf operator.
"""
struct FEConstant <: OperatorDeclaration
    id::Symbol # Id is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    ids::Tuple
end
netid(fec::FEConstant) = first(fec.ids)
partid(fec::FEConstant) = last(fec.ids) # Parent can be enumeration sort
sortof(fec::FEConstant) = begin
    sort = sortof(namedsorts(decldict(netid(fec)))[partid(fec)]) #! sort of partition or partition element
    return sort
end
(fec::FEConstant)() = fec.name # The value of a FEConstant is its name/identity. Not a `<:Number`.

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "(", repr(pid(fec)), ", ", repr(fec.name), ")")
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
#!TermInterface.symtype(op::FEConstant)   = error("NOT IMPLEMENTED: $(typeof(op))")

#:(variabledecls[id]) == maketerm(Expr, :ref, [variabledecls, id])

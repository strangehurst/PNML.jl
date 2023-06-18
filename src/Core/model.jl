"""
$(TYPEDEF)
$(TYPEDFIELDS)

One or more Petri Nets and an ID Registry shared by all nets.
"""
struct PnmlModel
    nets::Tuple{Vararg{PnmlNet}} #! Yes it is abstract.
    namespace::String
    reg::PnmlIDRegistry # Shared by all nets.
end

"""
$(TYPEDSIGNATURES)
"""

PnmlModel(nets::Tuple{Vararg{PnmlNet}}) = PnmlModel(nets, pnml_ns, registry())
PnmlModel(nets::Tuple{Vararg{PnmlNet}}, ns, reg::PnmlIDRegistry) = PnmlModel(nets, ns, reg)

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.
"""
nets(model::PnmlModel) = model.nets
namespace(model::PnmlModel) = model.namespace
idregistry(model::PnmlModel) = model.reg

"""
$(TYPEDSIGNATURES)
Return nets matching pntd `type` given as string, symbol or pnmltype singleton.
"""
function find_nets end
find_nets(model, str::AbstractString) = find_nets(model, pntd_symbol(str))
find_nets(model, sym::Symbol) = find_nets(model, pnmltype(sym))
find_nets(model, pntd::PnmlType) = find_nets(model, typeof(pntd))
find_nets(model, ::Type{T}) where {T<:PnmlType} = filter((Fix1(===, T) ∘ nettype), nets(model))

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing``.
"""
function find_net end

function find_net(model, id::Symbol)
    getfirst(Fix2(haspid, id), nets(model))
end

"""
$(TYPEDSIGNATURES)

Return first net contained by `doc`.
"""
first_net(model) = first(nets(model))

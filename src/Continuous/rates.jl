#---------------------------------------------------------------------------
# For some nets a transition is labeled with a floating point rate.
#---------------------------------------------------------------------------
rate_value_type(net::PnmlNet) = rate_value_type(nettype(net))
rate_value_type(pntd::PnmlType) = rate_value_type(typeof(pntd))
rate_value_type(::Type{T}) where {T <: PnmlType} = Float64

"""
$(TYPEDSIGNATURES)

Return a transition-id labelled vector of rate values for transitions of net.
"""
function rates end

function rates(pn::AbstractPetriNet)
    LVector( (; [tid => (rate ∘ transition)(pn, tid) for tid in transition_idset(pn)]...))
end

"""
$(TYPEDSIGNATURES)

Return rate value of `transition`.  Missing rate labels are defaulted to 0.0.
"""
function rate(transition)
    # Expected XML:
    # <rate> <text>0.3</text> </rate>
    #println("rate"); dump(transition)
    ishighlevel(nettype(transition)) &&
        throw(ArgumentError("The `rate` label is not supported for High-Level Petri Nets." *
                            "  Recommended to use a `ContinuousNet`."))
    pntd = nettype(transition)
    R = rate_value_type(pntd)
    if has_label(transition, :rate)
        r = get_label(transition, :rate)
        #@show r
        return numeric_label_value(R, r)
    end
    return zero(R)
end

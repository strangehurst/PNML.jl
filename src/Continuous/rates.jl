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
    LVector( (; [tid => (rate ∘ transition)(pn, tid) for tid in transition_ids(pn)]...))
end

"""
$(TYPEDSIGNATURES)

Return rate value of `transition`.  Missing rate labels are defaulted to 0.0.
"""
function rate(transition)
    # <rate> <text>0.3</text> </rate>
    ishighlevel(nettype(transition)) && throw(ArgumentError("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to use a `ContinuousNet`.
    """))
    pntd = nettype(transition)
    r = get_label(transition, :rate)
    if !isnothing(r)
        if haskey(r.dict, :text)
            !isnothing(r.dict[:text])
            # The unclaimed label mechanism adds a :content key for text elements.
            value = number_value(rate_value_type(pntd), r.dict[:text][1][:content])
        elseif haskey(r.dict, :content)
            # When the text element is elided, there is still a :content.
            value = number_value(rate_value_type(pntd), r.dict[:content])
        else
            throw(ArgumentError("`rate` tag missing a value"))
        end
        return value
    end
    return zero(rate_value_type(pntd))
end

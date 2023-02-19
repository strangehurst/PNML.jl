#---------------------------------------------------------------------------
# For some nets a transition is labeled with a floating point rate.
# NB: condition labels are part of high-level nets
#---------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return a transition-id labelled vector of rate values for transitions of net.
"""
function rates end

rate_value_type(pntd::PnmlType) = Float64
rate_value_type(::Type{T}) where {T <: PnmlType} = rate_value_type(T())
rate_value_type(net::PnmlNet) = rate_value_type(nettype(net))

function rates(pn::AbstractPetriNet)
    ishighlevel(nettype(pn)) && error("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to use a `ContinuousNet`.
    """)
    rates(pn, transition_ids(pn))
end

function rates(pn::AbstractPetriNet, idvec::Vector{Symbol})
    ishighlevel(nettype(pn)) && error("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to use a `ContinuousNet`.
    """)
    LVector( (; [transitionid => rate(pn, transitionid) for transitionid in idvec]...))
end

"""
$(TYPEDSIGNATURES)

Return rate value of `transition`.  Mising rate labels are defaulted to 0.0.
"""
function rate end

function rate(pn::AbstractPetriNet, tid::Symbol)
    ishighlevel(nettype(pn)) && error("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to us a `ContinuousNet`.
    """)
    (rate ∘ transition)(pn, tid)
end

function rate(transition)::Float64
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
            value = number_value(rate_value_type(pntd), r.dict[:text][:content])
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

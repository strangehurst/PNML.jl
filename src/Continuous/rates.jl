#---------------------------------------------------------------------------
# For some nets a transition is labeled with a floating point rate.
# NB: condition labels are part of high-level nets
#---------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return a transition-id labelled vector of rate values for transitions of net.
"""
function rates end

const rate_value_type = Float64

function rates(pn::PetriNet)
    ishighlevel(nettype(pn)) && error("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to use a `ContinuousNet`.
    """)
    rates(pn, transition_ids(pn))
end

function rates(pn::PetriNet, idvec::Vector{Symbol})
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

function rate(pn::PetriNet, tid::Symbol)
    ishighlevel(nettype(pn)) && error("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to us a `ContinuousNet`.
    """)
    (rate ∘ transition)(pn, tid)
end

function rate(transition)::Float64
    # <rate> <text>0.3</text> </rate>
    ishighlevel(nettype(transition)) && error("""
    The `rate` label is not supported for High-Level Petri Nets.
    Is recommended to us a `ContinuousNet`.
    """)
    r = get_label(transition, :rate)
    if isnothing(r)
        return zero(rate_value_type)
    else
        @assert tag(r) === :rate
        if haskey(r.dict, :text)
            !isnothing(r.dict[:text])
            # The unclaimed label mechanism adds a :content key for text elements.
            value = number_value(r.dict[:text][:content])
        elseif haskey(r.dict, :content)
            # When the text element is elided, there is still a :content.
            value = number_value(r.dict[:content])
        else
            value = nothing
        end
        return isnothing(value) ? zero(rate_value_type) : value
    end
end

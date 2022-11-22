#---------------------------------------------------------------------------
# For some nets a transition is labeled with a floating point rate.
# NB: condition labels are part of high-level nets
#---------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return a transition-id labelled vector of rate values for transitions of net.
"""
function rates end

rates(pn::PetriNet) = rates(pn, transition_ids(pn))

function rates(pn::PetriNet, idvec::Vector{Symbol})
    LVector( (; [transitionid => rate(pn, transitionid) for transitionid in idvec]...))
end

"""
$(TYPEDSIGNATURES)

Return rate value of `transition`.  Mising rate labels are defaulted to 0.0.
"""
function rate end
function rate(transition)::Float64
    # <rate> <text>0.3</text> </rate>
    r = get_label(transition, :rate)
    if isnothing(r)
        return zero(Float64)
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
            value = zero(Float64)
        end
        return isnothing(value) ? zero(Float64) : value #! specialize default value?
    end
end

function rate(pn::PetriNet, tid::Symbol)
    rate(transition(pn, tid))
end

"""
"""
struct TransitionRate{T} <: Annotation
    value::T
end

Base.eltype(r::TransitionRate) = typeof(value(r))
value(r::TransitionRate) = r.value

 """
$(TYPEDSIGNATURES)

Return rate value of `transition`.  Missing rate labels are defaulted to zero, or no delay.
"""
function rate(transition)
    # Expected XML: <rate> <text>0.3</text> </rate>

    # Allow any net type to have a rate label.
    R = rate_value_type(nettype(transition))

    if has_label(transition, :rate)
        r = get_label(transition, :rate)
        #@show r typeof(elements(r))
        str = text_content(elements(r)) #TODO place into an TransitionRate object.
        return number_value(R, str)
    end
    return zero(R)
end
function parse_rate()
    str = text_content(elements(r))
end

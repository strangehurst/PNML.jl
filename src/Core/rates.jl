
 """
$(TYPEDSIGNATURES)

Return rate value of `transition`.  Missing rate labels are defaulted to zero.
"""
function rate(transition)
    # Expected XML: <rate> <text>0.3</text> </rate>

    # Allow any net type to have a rate label.
    R = rate_value_type(nettype(transition))

    if has_label(transition, :rate)
        r = get_label(transition, :rate)
        str = text_content(elements(r))
        return number_value(R, str)
    end
    return zero(R)
end

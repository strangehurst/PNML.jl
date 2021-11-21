"""
$(TYPEDSIGNATURES)

High-level place-transition nets (HL-PTNet) have a toolspecific structure
defined for token graphics. Contains <tokenposition> tags.
"""
function parse_tokengraphics(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "tokengraphics" || error("element name wrong: $nn")
    positions = parse_node.(allchildren("tokenposition",node); kwargs...)
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :positions=>positions)
    d
end

"""
$(TYPEDSIGNATURES)

Position is a coordinate relative to containing element. Units are points.
"""
function parse_tokenposition(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "tokenposition" || error("element name wrong: $nn")
    parse_graphics_coordinate(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)

Arcs, Annotations and Nodes (places, transitions, pages) have different graphics semantics.
Return a dictonary with the union of possibilities.
"""
function parse_graphics(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "graphics" || error("element name wrong: $nn")

    d = PnmlDict(:tag=>Symbol(nn),
                 :line=>nothing, :positions=>PnmlDict[], :dimension=>nothing,
                 :fill=>nothing, :font=>nothing, :offset=>nothing,
                 :xml=>includexml(node))
    foreach(elements(node)) do child
        @match nodename(child) begin 
            "dimension" => (d[:dimension] = parse_graphics_coordinate(child; kwargs...))
            "fill"      => (d[:fill] = parse_graphics_fill(child; kwargs...))
            "font"      => (d[:font] = parse_graphics_font(child; kwargs...))
            "line"      => (d[:line] = parse_graphics_line(child; kwargs...))
            "offset"    => (d[:offset] = parse_graphics_coordinate(child; kwargs...))
            "position"  => (push!(d[:positions], parse_graphics_coordinate(child; kwargs...)))
            _ => @warn "ignoring graphics child '$(child)'"
        end
    end
    d
end

#
# Any xml node information will be attached to the graphics node.
# Use that to inspect the source XML for children of graphics nodes.
#
"""
$(TYPEDSIGNATURES)
"""
function parse_graphics_line(node; kwargs...)
    @debug node
    nn = nodename(node)
    (nn == "line") || error("element name wrong: $nn: $nn")
    color = has_color(node) ? node["color"] : nothing
    shape = has_shape(node) ? node["shape"] : nothing
    style = has_style(node) ? node["style"] : nothing
    width = has_width(node) ? node["width"] : nothing

    PnmlDict(:tag=>Symbol(nn), :shape=>shape, :color=>color, :width=>width, :style=>style)
end

"""
$(TYPEDSIGNATURES)

Coordinates `x`, `y` are in points.
"""
function parse_graphics_coordinate(node; kwargs...)
    @debug node
    nn = nodename(node)
    
    (nn=="position" || nn=="dimension" ||
     nn=="offset" || nn=="tokenposition") || error("element name wrong: $nn")
    has_x(node) || throw(MalformedException("$(nn) missing x", node))
    has_y(node) || throw(MalformedException("$(nn) missing y", node))
    # Specification seems to use integer pixels (or points).
    # We also allow Real numbers.
    x = number_value(node["x"])
    y = number_value(node["y"])
    PnmlDict(:tag=>Symbol(nn), :x=>x, :y=>y)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_graphics_fill(node; kwargs...)
    @debug node
    nn = nodename(node)
    (nn == "fill") || error("element name wrong: $nn")
    
    clr  = has_color(node) ? node["color"] : nothing
    img  = has_image(node) ? node["image"] : nothing
    gclr = has_gradient_color(node)    ? node["gradient-color"] : nothing
    grot = has_gradient_rotation(node) ? node["gradient-rotation"] : nothing
    
    PnmlDict(:tag=>Symbol(nn), :color=>clr, :image=>img,
             :gradient_color=>gclr, :gradient_rotation=>grot)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_graphics_font(node; kwargs...)
    @debug node
    nn = nodename(node)
    (nn == "font") || error("element name wrong: $nn")
    
    align  = has_align(node)      ? node["align"] : nothing
    deco   = has_decoration(node) ? node["decoration"] : nothing
    family = has_family(node)     ? node["family"] : nothing
    rot    = has_rotation(node)   ? node["rotation"] : nothing
    size   = has_size(node)       ? node["size"] : nothing
    style  = has_style(node)      ? node["style"] : nothing
    weight = has_weight(node)     ? node["weight"] : nothing
    
    PnmlDict(:tag=>Symbol(nn), :family=>family, :style=>style, :weight=>weight,
             :size=>size, :decoration=>deco, :align=>align, :rotation=>rot)
end

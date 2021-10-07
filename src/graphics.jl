

"High-level place-transition nets have a toolspecific structure defined for token graphics."
function parse_tokengraphics(node)
    @debug node
    nn = nodename(node)
    nn == "tokengraphics" || error("parse_tokengraphics element name wrong: $nn")
    positions = parse_node.(allchildren("tokenposition",node))
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :positions=>positions)
    d
end

"Position is relative to containing element. Units are points."
function parse_tokenposition(node)
    @debug node
    nn = nodename(node)
    nn == "tokenposition" || error("parse_ element name wrong: $nn")
    parse_graphics_coordinate(node)
end



"""
    parse_graphics
Arcs, Annotations and Nodes (places, transitions, pages) have different graphics semantics.
Return a dictonary with the union of possibilities.
"""
function parse_graphics(node)
    @debug node
    nn = nodename(node)
    nn == "graphics" || error("parse_graphics element name wrong: $nn")

    d = PnmlDict(:tag=>Symbol(nn),
                 :line=>nothing, :positions=>[], :dimension=>nothing,
                 :fill=>nothing, :font=>nothing, :offset=>nothing,
                 :xml=>includexml(node))
    foreach(elements(node)) do child
        @match nodename(child) begin 
            "dimension" => (d[:dimension] = parse_graphics_coordinate(child))
            "fill"      => (d[:fill] = parse_graphics_fill(child))
            "font"      => (d[:font] = parse_graphics_font(child))
            "line"      => (d[:line] = parse_graphics_line(child))
            "offset"    => (d[:offset] = parse_graphics_coordinate(child))
            "position"  => (push!(d[:positions], parse_graphics_coordinate(child)))
            _ => @warn "ignoring graphics child '$(child)'"
        end
    end
    d
end

#
# Any xml node information will be attached to the graphics node.
# Use that to inspect the source XML for children of graphics nodes.
#

function parse_graphics_line(node)
    @debug node
    nn = nodename(node)
    (nn == "line") || error("parse_graphics_line element name wrong: $nn: $nn")
    color = has_color(node) ? node["color"] : nothing
    shape = has_shape(node) ? node["shape"] : nothing
    style = has_style(node) ? node["style"] : nothing
    width = has_width(node) ? node["width"] : nothing

    (; :tag=>Symbol(nn), :shape=>shape, :color=>color, :width=>width, :style=>style)
end

"""
Coordinates `x`, `y` are in points.
"""
function parse_graphics_coordinate(node)
    @debug node
    nn = nodename(node)
    
    (nn=="position" || nn=="dimension" ||
     nn=="offset" || nn=="tokenposition") || error("$(nn) element name wrong: $nn")
    has_x(node) || throw(MalformedException("$(nn) missing x", node))
    has_y(node) || throw(MalformedException("$(nn) missing y", node))
    # Specification seems to use integer pixels (or points).
    # We also allow Real numbers.
    x = number_value(node["x"])
    y = number_value(node["y"])
    (; :tag=>Symbol(nn), :x=>x, :y=>y)
end

function parse_graphics_fill(node)
    @debug node
    nn = nodename(node)
    (nn == "fill") || error("parse_graphics_fill element name wrong: $nn")
    
    clr  = has_color(node) ? node["color"] : nothing
    img  = has_image(node) ? node["image"] : nothing
    gclr = has_gradient_color(node)    ? node["gradient-color"] : nothing
    grot = has_gradient_rotation(node) ? node["gradient-rotation"] : nothing
    
    (; :tag=>Symbol(nn), :color=>clr, :image=>img, :gradient_color=>gclr, :gradient_rotation=>grot)
end

function parse_graphics_font(node)
    @debug node
    nn = nodename(node)
    (nn == "font") || error("parse_graphics_font element name wrong: $nn")
    
    align  = has_align(node)      ? node["align"] : nothing
    deco   = has_decoration(node) ? node["decoration"] : nothing
    family = has_family(node)     ? node["family"] : nothing
    rot    = has_rotation(node)   ? node["rotation"] : nothing
    size   = has_size(node)       ? node["size"] : nothing
    style  = has_style(node)      ? node["style"] : nothing
    weight = has_weight(node)     ? node["weight"] : nothing
    
    (; :tag=>Symbol(nn), :family=>family, :style=>style, :weight=>weight,
     :size=>size, :decoration=>deco, :align=>align, :rotation=>rot)
end

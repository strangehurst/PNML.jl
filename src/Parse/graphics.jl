"""
$(TYPEDSIGNATURES)

High-level place-transition nets (HL-PTNet) have a toolspecific structure
defined for token graphics. Contains <tokenposition> tags.
"""
function parse_tokengraphics(node; kwargs...)
    nn = nodename(node)
    nn == "tokengraphics" || error("element name wrong: $nn")

    pnml_label_defaults(node, :tag => Symbol(nn),
                        :position => parse_node.(allchildren("tokenposition",node); kwargs...))
end

"""
$(TYPEDSIGNATURES)

Position is a coordinate relative to containing element. Units are points.
"""
function parse_tokenposition(node; kwargs...)
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

    d = PnmlDict(:tag => Symbol(nn),
                 :line => nothing, :positions => Coordinate[], :dimension => nothing,
                 :fill => nothing, :font => nothing, :offset => nothing,
                 :xml => includexml(node))
    foreach(elements(node)) do child
        @match nodename(child) begin 
            "dimension" => (d[:dimension] = parse_graphics_coordinate(child; kwargs...))
            "fill"      => (d[:fill] = parse_graphics_fill(child; kwargs...))
            "font"      => (d[:font] = parse_graphics_font(child; kwargs...))
            "line"      => (d[:line] = parse_graphics_line(child; kwargs...))
            "offset"    => (d[:offset] = parse_graphics_coordinate(child; kwargs...))
            "position"  => (push!(d[:positions], parse_graphics_coordinate(child; kwargs...)))
            _ => @warn "ignoring <graphics> child '$(child)'"
        end
    end
    g = Graphics(;dim=d[:dimension],
                 fill=d[:fill],
                 font=d[:font],
                 line=d[:line],
                 offset=d[:offset],
                 position=d[:positions])
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

    Line(;shape, color, width, style)
end

"""
$(TYPEDSIGNATURES)

Coordinates `x`, `y` are in points.
Specification seems to only use integers, we also allow real numbers.
"""
function parse_graphics_coordinate(node; kwargs...)
    nn = nodename(node)    
    (nn=="position" || nn=="dimension" ||
     nn=="offset" || nn=="tokenposition") || error("element name wrong: $nn")

    has_x(node) || throw(MalformedException("$(nn) missing x", node))
    has_y(node) || throw(MalformedException("$(nn) missing y", node))

    Coordinate(number_value(node["x"]), number_value(node["y"]))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_graphics_fill(node; kwargs...)
    nn = nodename(node)
    (nn == "fill") || error("element name wrong: $nn")
    
    clr  = has_color(node) ? node["color"] : nothing
    img  = has_image(node) ? node["image"] : nothing
    gclr = has_gradient_color(node)    ? node["gradient-color"] : nothing
    grot = has_gradient_rotation(node) ? node["gradient-rotation"] : nothing
    
    Fill(color=clr, image=img, gradient_color=gclr, gradient_rotation=grot)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_graphics_font(node; kwargs...)
    @show node
    nn = nodename(node)
    (nn == "font") || error("element name wrong: $nn")
    
    align  = has_align(node)      ? node["align"] : nothing
    deco   = has_decoration(node) ? node["decoration"] : nothing
    family = has_family(node)     ? node["family"] : nothing
    rot    = has_rotation(node)   ? node["rotation"] : nothing
    size   = has_size(node)       ? node["size"] : nothing
    style  = has_style(node)      ? node["style"] : nothing
    weight = has_weight(node)     ? node["weight"] : nothing
    
    Font(family=family, style=style, weight=weight,
             size=size, decoration=deco, align=align, rotation=rot)
end

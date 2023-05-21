"""
$(TYPEDSIGNATURES)

High-level place-transition nets (HL-PTNet) have a toolspecific structure
defined for token graphics. Contains <tokenposition> tags.
"""
function parse_tokengraphics(node::XMLNode, pntd::PnmlType, reg)
    nn = check_nodename(node, "tokengraphics")
    if !haselement(node)
        TokenGraphics{coordinate_value_type(pntd)}() # Empty is legal.
    else
        positions = allchildren("tokenposition", node) #TODO use iterator
        isempty(positions) &&
                throw(MalformedException("$nn must have at least one <tokenposition>, found none"), node)
        tpos = parse_tokenposition.(positions, Ref(pntd), Ref(reg))
        (isnothing(tpos) || isempty(tpos)) &&
                throw(MalformedException("$nn did not parse positions", node))
        TokenGraphics{coordinate_value_type(pntd)}(tpos)
    end
end

"""
$(TYPEDSIGNATURES)

Return Cartesian [`Coordinate`](@ref) relative to containing element.
"""
function parse_tokenposition(node, pntd, reg)
    check_nodename(node, "tokenposition")
    parse_graphics_coordinate(node, pntd, reg)
end

"""
$(TYPEDSIGNATURES)

Arcs, Annotations and Nodes have different graphics semantics.
Return a [`Graphics`](@ref) holding the union of possibilities.
"""
function parse_graphics(node, pntd, reg)
    nn = check_nodename(node, "graphics")
    _positions = Coordinate{coordinate_value_type(pntd)}[]
    args = NamedTuple()
    for child in eachelement(node)
        @match nodename(child) begin
            "dimension" => (args = merge(args, (dimension = parse_graphics_coordinate(child, pntd, reg),)))
            "fill"      => (args = merge(args, (fill = parse_graphics_fill(child, pntd, reg),)))
            "font"      => (args = merge(args, (font = parse_graphics_font(child, pntd, reg),)))
            "line"      => (args = merge(args, (line = parse_graphics_line(child, pntd, reg),)))
            "offset"    => (args = merge(args, (offset = parse_graphics_coordinate(child, pntd, reg),)))
            "position"  => push!(_positions, parse_graphics_coordinate(child, pntd, reg))
            _ => @warn "$nn ignoring <graphics> child '$child'"
        end
    end
    args = merge(args, (positions = _positions,))

    Graphics{coordinate_value_type(pntd)}(; args...)
end

"""
$(TYPEDSIGNATURES)

Return [`Line`](@ref).
"""
function parse_graphics_line(node, pntd, reg)
    check_nodename(node, "line")
    args = NamedTuple()
    EzXML.haskey(node, "color") && (args = merge(args, (color = node["color"],)))
    EzXML.haskey(node, "shape") && (args = merge(args, (shape = node["shape"],)))
    EzXML.haskey(node, "style") && (args = merge(args, (style = node["style"],)))
    EzXML.haskey(node, "width") && (args = merge(args, (width = node["width"],)))
    isempty(args) ? Line() : Line(; args...)
end

"""
$(TYPEDSIGNATURES)

Return [`Coordinate`](@ref).
Specification seems to only use integers, we also allow real numbers.
"""
function parse_graphics_coordinate(node, pntd, reg)
    nn = nodename(node)
    if !(nn=="position" || nn=="dimension" || nn=="offset" || nn=="tokenposition")
        error("element name wrong: $nn")
    end

    EzXML.haskey(node, "x") || throw(MalformedException("$nn missing x", node))
    EzXML.haskey(node, "y") || throw(MalformedException("$nn missing y", node))

    Coordinate(number_value(coordinate_value_type(pntd), node["x"]),
               number_value(coordinate_value_type(pntd), node["y"]))
end

"""
$(TYPEDSIGNATURES)

Return [`Fill`](@ref)
"""
function parse_graphics_fill(node, pntd, reg)
    check_nodename(node, "fill")
    args = NamedTuple()
    EzXML.haskey(node, "color") && (args = merge(args, (color = node["color"],)))
    EzXML.haskey(node, "image") && (args = merge(args, (image = node["image"],)))
    EzXML.haskey(node, "gradient-color")    && (args = merge(args, (gradient_color = node["gradient-color"],)))
    EzXML.haskey(node, "gradient-rotation") && (args = merge(args, (gradient_rotation = node["gradient-rotation"],)))
    isempty(args) ? Fill() : Fill(; args...)
end

"""
$(TYPEDSIGNATURES)

Return [`Font`](@ref).
"""
function parse_graphics_font(node, pntd, reg)
    check_nodename(node, "font")
    args = NamedTuple()
    EzXML.haskey(node, "style")      && (args = merge(args, (style = node["style"],)))
    EzXML.haskey(node, "align")      && (args = merge(args, (align = node["align"],)))
    EzXML.haskey(node, "decoration") && (args = merge(args, (decoration = node["decoration"],)))
    EzXML.haskey(node, "family")     && (args = merge(args, (family = node["family"],)))
    EzXML.haskey(node, "rotation")   && (args = merge(args, (rotation = node["rotation"],)))
    EzXML.haskey(node, "size")       && (args = merge(args, (size   = node["size"],)))
    EzXML.haskey(node, "weight")     && (args = merge(args, (weight = node["weight"],)))
    isempty(args) ? Font() : Font(; args...)
end

"""
$(TYPEDSIGNATURES)

High-level place-transition nets (HL-PTNet) have a toolspecific structure
defined for token graphics. Contains <tokenposition> tags.
"""
function parse_tokengraphics(node::XMLNode, pntd::PnmlType, reg)
    nn = check_nodename(node, "tokengraphics")
    if !haselement(node)
        TokenGraphics() # Empty is legal.
    else
        positions = allchildren("tokenposition", node) #TODO use iterator
        isempty(positions) &&
                throw(MalformedException("$nn must have at least one <tokenposition>, found none"), node)
        tpos = parse_tokenposition.(positions, Ref(pntd), Ref(reg))
        (isnothing(tpos) || isempty(tpos)) &&
                throw(MalformedException("$nn did not parse positions", node))
        TokenGraphics(tpos)
    end
end

"""
$(TYPEDSIGNATURES)

Cartesian coordinate relative to containing element.
"""
function parse_tokenposition(node, pntd, reg)
    nn = nodename(node)
    nn == "tokenposition" || error("element name wrong: $nn")

    parse_graphics_coordinate(node, pntd, reg)
end

"""
$(TYPEDSIGNATURES)

Arcs, Annotations and Nodes have different graphics semantics.
Return a [`Graphics`](@ref) holding the union of possibilities.
"""
function parse_graphics(node, pntd, reg)
    nn = check_nodename(node, "graphics")
    @debug nn

    d = PnmlDict(:tag => Symbol(nn),
                :dimension => Coordinate{coordinate_value_type(pntd)}(),
                :line => nothing,
                :fill => nothing,
                :font => nothing,
                :offset => Coordinate{coordinate_value_type(pntd)}(),
                :positions => Coordinate{coordinate_value_type(pntd)}[],
    )
    for child in eachelement(node)
        @match nodename(child) begin
            "dimension" => (d[:dimension] = parse_graphics_coordinate(child, pntd, reg))
            "fill"      => (d[:fill] = parse_graphics_fill(child, pntd, reg))
            "font"      => (d[:font] = parse_graphics_font(child, pntd, reg))
            "line"      => (d[:line] = parse_graphics_line(child, pntd, reg))
            "offset"    => (d[:offset] = parse_graphics_coordinate(child, pntd, reg))
            "position"  => (push!(d[:positions], parse_graphics_coordinate(child, pntd, reg)))
            _ => @warn "ignoring <graphics> child '$(child)'"
        end
    end
    let PNTD=typeof(pntd), dimension = d[:dimension], fill = d[:fill], font = d[:font], line = d[:line], offset = d[:offset], positions = d[:positions]
        @show typeof(dimension) typeof(fill) typeof(font) typeof(line) typeof(offset) typeof(positions)
        Graphics( ; dimension, fill, font, line, offset, positions)
    end
end

"""
$(TYPEDSIGNATURES)

Return [`Line`](@ref).
"""
function parse_graphics_line(node, pntd, reg)
    nn = nodename(node)
    (nn == "line") || error("element name wrong: $nn")

    let color = EzXML.haskey(node, "color") ? node["color"] : nothing,
        shape = EzXML.haskey(node, "shape") ? node["shape"] : nothing,
        style = EzXML.haskey(node, "style") ? node["style"] : nothing,
        width = EzXML.haskey(node, "width") ? node["width"] : nothing
        @nospecialize
        Line( ; shape, color, width, style)
    end
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
    nn = nodename(node)
    (nn == "fill") || error("element name wrong: $nn")

    let color  = EzXML.haskey(node, "color") ? node["color"] : nothing,
        image  = EzXML.haskey(node, "image") ? node["image"] : nothing,
        gradient_color = EzXML.haskey(node, "gradient-color")    ? node["gradient-color"] : nothing,
        gradient_rotation = EzXML.haskey(node, "gradient-rotation") ? node["gradient-rotation"] : nothing
        @nospecialize
        Fill( ; color , image, gradient_color, gradient_rotation)
    end
end

"""
$(TYPEDSIGNATURES)

Return [`Font`](@ref).
"""
function parse_graphics_font(node, pntd, reg)
    nn = nodename(node)
    (nn == "font") || error("element name wrong: $nn")

    let align  = EzXML.haskey(node, "align")      ? node["align"] : nothing,
        decoration = EzXML.haskey(node, "decoration") ? node["decoration"] : nothing,
        family = EzXML.haskey(node, "family")     ? node["family"] : nothing,
        rotation = EzXML.haskey(node, "rotation")   ? node["rotation"] : nothing,
        size   = EzXML.haskey(node, "size")       ? node["size"] : nothing,
        style  = EzXML.haskey(node, "style")      ? node["style"] : nothing,
        weight = EzXML.haskey(node, "weight")     ? node["weight"] : nothing

        Font( ; family, style, weight, size, decoration, align, rotation)
    end
end

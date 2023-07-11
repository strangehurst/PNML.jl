"""
$(TYPEDSIGNATURES)

High-level place-transition nets (HL-PTNet) have a toolspecific structure
defined for token graphics. Contains <tokenposition> tags.
"""
function parse_tokengraphics(node::XMLNode, pntd::PnmlType, reg)
    nn = check_nodename(node, "tokengraphics")
    positions = allchildren("tokenposition", node) # returns Vector{XMLNode}
    if isnothing(positions) || isempty(positions)
        @warn "$nn does not have any <tokenposition> elements"
        TokenGraphics{coordinate_value_type(pntd)}() # Empty is legal.
    else
        tpos = parse_tokenposition.(positions, Ref(pntd), Ref(reg)) #! broadcast fills array
        (isnothing(tpos) || isempty(tpos)) && throw(MalformedException("$nn did not parse positions"))
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
    args = Dict()
    _positions = Coordinate{coordinate_value_type(pntd)}[]
    for child in eachelement(node)
        @match nodename(child) begin
            "dimension" => (args[:dimension] = parse_graphics_coordinate(child, pntd, reg))
            "fill"      => (args[:fill] = parse_graphics_fill(child, pntd, reg))
            "font"      => (args[:font] = parse_graphics_font(child, pntd, reg))
            "line"      => (args[:line] = parse_graphics_line(child, pntd, reg))
            "offset"    => (args[:offset] = parse_graphics_coordinate(child, pntd, reg))
            "position"  => push!(_positions, parse_graphics_coordinate(child, pntd, reg))
            _ => @warn "$nn ignoring <graphics> child '$child'"
        end
    end
    args[:positions] = _positions
    Graphics{coordinate_value_type(pntd)}(; pairs(args)...)
end

"""
$(TYPEDSIGNATURES)

Return [`Line`](@ref).
"""
function parse_graphics_line(node, pntd, reg)
    check_nodename(node, "line")
    args = Dict()
    EzXML.haskey(node, "color") && (args[:color] = node["color"])
    EzXML.haskey(node, "shape") && (args[:shape] = node["shape"])
    EzXML.haskey(node, "style") && (args[:style] = node["style"])
    EzXML.haskey(node, "width") && (args[:width] = node["width"])
    Line(; pairs(args)...)
end

"""
$(TYPEDSIGNATURES)

Return [`Coordinate`](@ref).
Specification seems to only use integers, we also allow real numbers.
"""
function parse_graphics_coordinate(node, pntd, reg)
    nn = nodename(node)
    if !(nn=="position" || nn=="dimension" || nn=="offset" || nn=="tokenposition")
        throw(ArgumentError("element name wrong: $nn"))
    end

    EzXML.haskey(node, "x") || throw(MalformedException("$nn missing x"))
    EzXML.haskey(node, "y") || throw(MalformedException("$nn missing y"))

    Coordinate(number_value(coordinate_value_type(pntd), node["x"]),
               number_value(coordinate_value_type(pntd), node["y"]))
end

"""
$(TYPEDSIGNATURES)

Return [`Fill`](@ref)
"""
function parse_graphics_fill(node, pntd, reg)
    check_nodename(node, "fill")
    args = Dict()
    EzXML.haskey(node, "color") && (args[:color] = node["color"])
    EzXML.haskey(node, "image") &&  (args[:image] = node["image"])
    EzXML.haskey(node, "gradient-color")    && (args[:gradient_color] = node["gradient-color"])
    EzXML.haskey(node, "gradient-rotation") && (args[:gradient_rotation] = node["gradient-rotation"])
    Fill(; args...)
end

"""
$(TYPEDSIGNATURES)

Return [`Font`](@ref).
"""
function parse_graphics_font(node, pntd, reg)
    check_nodename(node, "font")
    args = Dict()
    EzXML.haskey(node, "weight")     && (args[:weight] = node["weight"])
    EzXML.haskey(node, "style")      && (args[:style] = node["style"])
    EzXML.haskey(node, "align")      && (args[:align] = node["align"])
    EzXML.haskey(node, "decoration") && (args[:decoration] = node["decoration"])
    EzXML.haskey(node, "family")     && (args[:family] = node["family"])
    EzXML.haskey(node, "rotation")   && (args[:rotation] = node["rotation"])
    EzXML.haskey(node, "size")       && (args[:size]   = node["size"])
    Font(; pairs(args)...)
end

"""
$(TYPEDSIGNATURES)

Parse high-level place-transition net's (HL-PTNet) toolspecific structure defined for token graphics.
See [`Labels.TokenGraphics`](@ref) and [`parse_tokenposition`](@ref).
"""
function parse_tokengraphics(node::XMLNode, pntd::PnmlType)
    nn = check_nodename(node, "tokengraphics")
    tpos = PNML.coordinate_type(pntd)[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "tokenposition"
            push!(tpos, parse_tokenposition(child, pntd))
        else
            @warn "ignoring unexpected child of <tokengraphics>: '$tag'"
        end
    end
    if isempty(tpos)
        @warn "tokengraphics does not have any <tokenposition> elements"
    end
    Labels.TokenGraphics(tpos)
end

"""
$(TYPEDSIGNATURES)

Return Cartesian [`Coordinate`](@ref) relative to containing element.
"""
function parse_tokenposition(node, pntd)
    check_nodename(node, "tokenposition")
    parse_graphics_coordinate(node, pntd)
end

"""
$(TYPEDSIGNATURES)

Arcs, Annotations and Nodes have different graphics semantics.
Return a [`Graphics`](@ref PnmlGraphics.Graphics) holding the union of possibilities.
"""
function parse_graphics(node, pntd)
    nn = check_nodename(node, "graphics")
    args = Dict()
    _positions = Coordinate{PNML.coordinate_value_type(pntd)}[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag ==   "dimension"
            args[:dimension] = parse_graphics_coordinate(child, pntd)
        elseif tag == "fill"
            args[:fill] = parse_graphics_fill(child, pntd)
        elseif tag ==    "font"
            args[:font] = parse_graphics_font(child, pntd)
        elseif tag ==     "line"
            args[:line] = parse_graphics_line(child, pntd)
        elseif tag ==     "offset"
            args[:offset] = parse_graphics_coordinate(child, pntd)
        elseif tag ==     "position"
            push!(_positions, parse_graphics_coordinate(child, pntd))
        else
            @warn "ignoring unexpected child of <graphics>: '$tag'"
        end
    end
    args[:positions] = _positions
    Graphics{PNML.coordinate_value_type(pntd)}(; pairs(args)...)
end

"""
$(TYPEDSIGNATURES)

Return [`Line`](@ref PnmlGraphics.Line).
"""
function parse_graphics_line(node, pntd)
    check_nodename(node, "line")
    args = Dict()
    EzXML.haskey(node, "color") && (args[:color] = node["color"])
    EzXML.haskey(node, "shape") && (args[:shape] = node["shape"])
    EzXML.haskey(node, "style") && (args[:style] = node["style"])
    EzXML.haskey(node, "width") && (args[:width] = node["width"])
    PnmlGraphics.Line(; pairs(args)...)
end

"""
$(TYPEDSIGNATURES)

Return [`Coordinate`](@ref PnmlGraphics.Coordinate).
Specification seems to only use integers, we also allow real numbers.
"""
function parse_graphics_coordinate(node, pntd)
    nn = EzXML.nodename(node)
    if !(nn=="position" || nn=="dimension" || nn=="offset" || nn=="tokenposition")
        throw(ArgumentError("element name wrong: $nn"))
    end

    EzXML.haskey(node, "x") || throw(PNML.MalformedException("$nn missing x"))
    EzXML.haskey(node, "y") || throw(PNML.MalformedException("$nn missing y"))

    PnmlGraphics.Coordinate(PNML.number_value(PNML.coordinate_value_type(pntd), node["x"]),
                            PNML.number_value(PNML.coordinate_value_type(pntd), node["y"]))
end

"""
$(TYPEDSIGNATURES)

Return [`Fill`](@ref PnmlGraphics.Fill)
"""
function parse_graphics_fill(node, pntd)
    check_nodename(node, "fill")
    args = Dict()
    EzXML.haskey(node, "color") && (args[:color] = node["color"])
    EzXML.haskey(node, "image") &&  (args[:image] = node["image"])
    EzXML.haskey(node, "gradient-color")    && (args[:gradient_color] = node["gradient-color"])
    EzXML.haskey(node, "gradient-rotation") && (args[:gradient_rotation] = node["gradient-rotation"])
    PnmlGraphics.Fill(; args...)
end

"""
$(TYPEDSIGNATURES)

Return [`Font`](@ref PnmlGraphics.Font).
"""
function parse_graphics_font(node, pntd)
    check_nodename(node, "font")
    args = Dict()
    EzXML.haskey(node, "weight")     && (args[:weight] = node["weight"])
    EzXML.haskey(node, "style")      && (args[:style] = node["style"])
    EzXML.haskey(node, "align")      && (args[:align] = node["align"])
    EzXML.haskey(node, "decoration") && (args[:decoration] = node["decoration"])
    EzXML.haskey(node, "family")     && (args[:family] = node["family"])
    EzXML.haskey(node, "rotation")   && (args[:rotation] = node["rotation"])
    EzXML.haskey(node, "size")       && (args[:size]   = node["size"])
    PnmlGraphics.Font(; pairs(args)...)
end

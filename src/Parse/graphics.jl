"""
$(TYPEDSIGNATURES)

High-level place-transition nets (HL-PTNet) have a toolspecific structure
defined for token graphics. Contains <tokenposition> tags.
"""
function parse_tokengraphics(node, pntd; kw...)
    nn = nodename(node)
    nn == "tokengraphics" || error("element name wrong: $nn")
    positions = allchildren("tokenposition", node)
    if isempty(positions) 
        TokenGraphics() # Empty is legal.
    else
        #TODO: Enforce type sameness of position coordinates? How?
        TokenGraphics(parse_tokenposition.(positions, Ref(pntd); kw...))
    end
end

"""
Cartesian coordinate relative to containing element.

$(TYPEDSIGNATURES)
"""
function parse_tokenposition(node, pntd; kw...)
    nn = nodename(node)
    nn == "tokenposition" || error("element name wrong: $nn")

    parse_graphics_coordinate(node, pntd; kw...)
end

"""
Arcs, Annotations and Nodes have different graphics semantics.
Return a [`Graphics`](@ref) holding the union of possibilities.

$(TYPEDSIGNATURES)
"""
function parse_graphics(node, pntd; kw...)
    @debug node
    nn = nodename(node)
    nn == "graphics" || error("element name wrong: $nn")

    d = PnmlDict(:tag => Symbol(nn),
                 :line => nothing, :positions => Coordinate[], :dimension => nothing,
                 :fill => nothing, :font => nothing, :offset => nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin 
            "dimension" => (d[:dimension] = parse_graphics_coordinate(child, pntd; kw...))
            "fill"      => (d[:fill] = parse_graphics_fill(child, pntd; kw...))
            "font"      => (d[:font] = parse_graphics_font(child, pntd; kw...))
            "line"      => (d[:line] = parse_graphics_line(child, pntd; kw...))
            "offset"    => (d[:offset] = parse_graphics_coordinate(child, pntd; kw...))
            "position"  => (push!(d[:positions], parse_graphics_coordinate(child, pntd; kw...)))
            _ => @warn "ignoring <graphics> child '$(child)'"
        end
    end
    Graphics(;
             dim=d[:dimension],
             fill=d[:fill],
             font=d[:font],
             line=d[:line],
             offset=d[:offset],
             position=d[:positions])
end

"""
$(TYPEDSIGNATURES)

Return [`Line`](@ref).
"""
function parse_graphics_line(node, pntd; kw...)
    nn = nodename(node)
    (nn == "line") || error("element name wrong: $nn")

    color = EzXML.haskey(node, "color") ? node["color"] : nothing
    shape = EzXML.haskey(node, "shape") ? node["shape"] : nothing
    style = EzXML.haskey(node, "style") ? node["style"] : nothing
    width = EzXML.haskey(node, "width") ? node["width"] : nothing

    Line(; shape, color, width, style)
end

"""
$(TYPEDSIGNATURES)

Return [`Coordinate`](@ref).
Specification seems to only use integers, we also allow real numbers.
"""
function parse_graphics_coordinate(node, pntd; kw...)
    nn = nodename(node)    
    (nn=="position" || nn=="dimension" ||
     nn=="offset" || nn=="tokenposition") || error("element name wrong: $nn")

    EzXML.haskey(node, "x") || throw(MalformedException("$nn missing x", node))
    EzXML.haskey(node, "y") || throw(MalformedException("$nn missing y", node))

    Coordinate(number_value(node["x"]), number_value(node["y"]))
end

"""
$(TYPEDSIGNATURES)

Return [`Fill`](@ref)
"""
function parse_graphics_fill(node, pntd; kw...)
    nn = nodename(node)
    (nn == "fill") || error("element name wrong: $nn")
    
    clr  = EzXML.haskey(node, "color") ? node["color"] : nothing
    img  = EzXML.haskey(node, "image") ? node["image"] : nothing
    gclr = EzXML.haskey(node, "gradient-color")    ? node["gradient-color"] : nothing
    grot = EzXML.haskey(node, "gradient-rotation") ? node["gradient-rotation"] : nothing
    
    Fill(color=clr, image=img, gradient_color=gclr, gradient_rotation=grot)
end

"""
$(TYPEDSIGNATURES)

Return [`Font`](@ref).
"""
function parse_graphics_font(node, pntd; kw...)
    nn = nodename(node)
    (nn == "font") || error("element name wrong: $nn")
    
    align  = EzXML.haskey(node, "align")      ? node["align"] : nothing
    deco   = EzXML.haskey(node, "decoration") ? node["decoration"] : nothing
    family = EzXML.haskey(node, "family")     ? node["family"] : nothing
    rot    = EzXML.haskey(node, "rotation")   ? node["rotation"] : nothing
    size   = EzXML.haskey(node, "size")       ? node["size"] : nothing
    style  = EzXML.haskey(node, "style")      ? node["style"] : nothing
    weight = EzXML.haskey(node, "weight")     ? node["weight"] : nothing
    
    Font(; family, style, weight, size, decoration=deco, align, rotation=rot)
end


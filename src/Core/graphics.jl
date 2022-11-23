###############################################################################
# GRAPHICS
###############################################################################
"""
Cartesian Coordinate.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Coordinate
    x::Union{Int,Float64}
    y::Union{Int,Float64}
end
Coordinate() = Coordinate(0, 0)
Coordinate(x::Union{Int,Float64}) = Coordinate(x, zero(x))

#-------------------
"""
Fill attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Fill
    color::Maybe{String}
    image::Maybe{String}
    gradient_color::Maybe{String}
    gradient_rotation::Maybe{String}
end
function Fill(; color=nothing, image=nothing, gradient_color=nothing, gradient_rotation=nothing)
    Fill(color, image, gradient_color, gradient_rotation )
end

#-------------------
"""
Font attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Font
    family    ::Maybe{String}
    style     ::Maybe{String}
    weight    ::Maybe{String}
    size      ::Maybe{String}
    align     ::Maybe{String}
    rotation  ::Maybe{String}
    decoration::Maybe{String}
end
function Font(; family=nothing, style=nothing, weight=nothing,
              size=nothing, align=nothing, rotation=nothing, decoration=nothing)
    Font(family, style, weight, size, align, rotation, decoration)
end

#-------------------
"""
Line attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Line
    color::Maybe{String}
    shape::Maybe{String}
    style::Maybe{String}
    width::Maybe{String}
end
function Line(; color=nothing, shape=nothing, style=nothing, width=nothing)
    Line(color, shape, style, width)
end

#-------------------
"""
PNML Graphics can be attached to many parts of PNML models.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Graphics #{COORD,FILL,FONT,LINE}
    dimension::Maybe{Coordinate}
    fill::Maybe{Fill}
    font::Maybe{Font}
    line::Maybe{Line}
    offset::Maybe{Coordinate}
    position::Maybe{Vector{Coordinate}}
end

function Graphics(;dim=nothing, fill=nothing, font=nothing,
                  line=nothing, offset=nothing, position=nothing)
    Graphics(dim, fill, font, line, offset, position)
end

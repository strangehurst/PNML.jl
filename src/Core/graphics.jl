###############################################################################
# GRAPHICS
###############################################################################
"""
Cartesian Coordinate.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Coordinate{T}
    x::T
    y::T
end

Coordinate{T}() where {T <: Union{Int,Float64}} = Coordinate(zero(T), zero(T))
Coordinate(x::T) where {T <: Union{Int,Float64}} = Coordinate(x, zero(x))
#Coordinate(x::T, y::T) where {T <: Union{Int,Float64}} = Coordinate(x, y)

coordinate_type(::Type{T}) where {T <: PnmlType} = Coordinate{coordinate_value_type(T)}
coordinate_value_type(::Type{T}) where {T <: PnmlType} = Int
coordinate_value_type(::Type{T}) where {T <: AbstractContinuousNet} = Float64

#-------------------
"""
Fill attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Fill
    color::Maybe{String} = nothing
    image::Maybe{String} = nothing
    gradient_color::Maybe{String} = nothing
    gradient_rotation::Maybe{String} = nothing
end
#function Fill(; color=nothing, image=nothing, gradient_color=nothing, gradient_rotation=nothing)
#    Fill(color, image, gradient_color, gradient_rotation )
#end

#-------------------
"""
Font attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Font
    family    ::Maybe{String} = nothing
    style     ::Maybe{String} = nothing
    weight    ::Maybe{String} = nothing
    size      ::Maybe{String} = nothing
    align     ::Maybe{String} = nothing
    rotation  ::Maybe{String} = nothing
    decoration::Maybe{String} = nothing
end
#function Font(; family=nothing, style=nothing, weight=nothing,
#              size=nothing, align=nothing, rotation=nothing, decoration=nothing)
#    Font(family, style, weight, size, align, rotation, decoration)
#end

#-------------------
"""
Line attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Line
    color::Maybe{String} = nothing
    shape::Maybe{String} = nothing
    style::Maybe{String} = nothing
    width::Maybe{String} = nothing
end
#function Line(; color=nothing, shape=nothing, style=nothing, width=nothing)
#    Line(color, shape, style, width)
#end

#-------------------
"""
PNML Graphics can be attached to many parts of PNML models.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Graphics{COORD} #{COORD,FILL,FONT,LINE}
    dimension::COORD
    fill::Maybe{Fill}
    font::Maybe{Font}
    line::Maybe{Line}
    offset::COORD
    positions::Vector{COORD} = Vector{COORD}[]
end

@kwdef struct ArcGraphics{COORD}
    line::Line
    positions::Vector{COORD} # ordered
end

@kwdef struct NodeGraphics{COORD}
    postion::COORD
    dimension::COORD
    line::Line
    fill::Fill
end

@kwdef struct AnnotationGraphics{COORD}
    fill::Fill
    offset::COORD
    line::Line
    font::Font
end

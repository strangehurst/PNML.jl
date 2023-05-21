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

Coordinate{T}() where {T <: Union{ Int,Float64}} = Coordinate{T}(zero(T), zero(T))
#Coordinate(x::T) where {T <: Union{Int,Float64}} = Coordinate(x, zero(x))
#Coordinate(x::T, y::T) where {T <: Union{Int,Float64}} = Coordinate(x, y)

coordinate_type(::Type{T}) where {T <: PnmlType} = Coordinate{coordinate_value_type(T)}
coordinate_value_type(::Type{T}) where {T <: PnmlType} = Int
coordinate_value_type(::Type{T}) where {T <: AbstractContinuousNet} = Float64
eltype(::Coordinate{T}) where {T <: Union{Int, Float64}} = T

#-------------------
"""
Fill attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Fill
    color::String = ""
    image::String = ""
    gradient_color::String = ""
    gradient_rotation::String = ""
end

#-------------------
"""
Font attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Font
    family    ::String = ""
    style     ::String = ""
    weight    ::String = ""
    size      ::String = ""
    align     ::String = ""
    rotation  ::String = ""
    decoration::String = ""
end

#-------------------
"""
Line attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Line
    color::String = ""
    shape::String = ""
    style::String = ""
    width::String = ""
end

#-------------------
"""
PNML Graphics can be attached to many parts of PNML models.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Graphics{T <: Union{Int, Float64}}
    #{COORD,FILL,FONT,LINE}
    dimension::Coordinate{T} = Coordinate{T}()
    fill::Fill = Fill()
    font::Font = Font()
    line::Line = Line()
    offset::Coordinate{T} = Coordinate{T}()
    positions::Vector{Coordinate{T}} = Vector{Coordinate{T}}[] # ordered collection
end

@kwdef struct ArcGraphics{T <: Union{Int, Float64}}
    line::Line = line()
    positions::Vector{Coordinate{T}} = Vector{Coordinate{T}}[] # ordered collection
end

@kwdef struct NodeGraphics{T <: Union{Int, Float64}}
    postion::Coordinate{T} = Coordinate{T}()
    dimension::Coordinate{T} = Coordinate(one(T), one(T))
    line::Line = Line()
    fill::Fill = Fill()
end

@kwdef struct AnnotationGraphics{T <: Union{Int, Float64}}
    fill::Fill = Fill()
    offset::Coordinate{T} = Coordinate{T}()
    line::Line = Line()
    font::Font = Font()
end

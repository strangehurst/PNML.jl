###############################################################################
# GRAPHICS
###############################################################################
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Cartesian Coordinate are actually positive decimals. Ranges from 0 to 999.9.
"""
struct Coordinate{T <: Union{Int,Float64}} #! is decimal 0 to 999.9 is Schema
    x::T
    y::T
end

Coordinate{T}() where {T <: Union{Int,Float64}} = Coordinate{T}(zero(T), zero(T))

coordinate_type(::Type{T}) where {T <: PnmlType} = Coordinate{coordinate_value_type(T)}
coordinate_value_type(::Type{<: PnmlType}) = Int
coordinate_value_type(::Type{<: AbstractContinuousNet}) = Float64
Base.eltype(::Coordinate{T}) where {T} = T

#-------------------
"""
Fill attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Fill
    color::String = "black" # Required
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
    weight    ::String = "black" # Required
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
    color::String = "black" # Required
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
    dimension::Coordinate{T} = Coordinate{T}(one(T), one(T))
    fill::Fill = Fill(; color = "black")
    font::Font = Font(; weight = "black")
    line::Line = Line(; color = "black")
    offset::Coordinate{T} = Coordinate{T}(zero(T), zero(T))
    positions::Vector{Coordinate{T}} = Vector{Coordinate{T}}[] # ordered collection
end

@kwdef struct ArcGraphics{T <: Union{Int, Float64}}
    line::Line = Line(; color = "black")
    positions::Vector{Coordinate{T}} = Vector{Coordinate{T}}[] # ordered collection
end

@kwdef struct NodeGraphics{T <: Union{Int, Float64}}
    postion::Coordinate{T} = Coordinate{T}()
    dimension::Coordinate{T} = Coordinate(one(T), one(T))
    line::Line = Line(; color = "black")
    fill::Fill = Fill(; color = "black")
end

@kwdef struct AnnotationGraphics{T <: Union{Int, Float64}}
    fill::Fill = Fill(; color = "black")
    offset::Coordinate{T} = Coordinate{T}(zero(T), zero(T))
    line::Line = Line(; color = "black")
    font::Font = Font(; weight = "black")
end

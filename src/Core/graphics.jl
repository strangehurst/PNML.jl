###############################################################################
# GRAPHICS
###############################################################################
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Cartesian Coordinate are actually positive decimals. Ranges from 0 to 999.9.
"""
struct Coordinate{T <: DecFP.DecimalFloatingPoint} #! is decimal 0 to 999.9 in Schema
    x::T
    y::T
end

"""
Construct a Coordinate from mixed Int, Float64.
"""
Coordinate(x::T1, y::T2) where {T1 <: Union{Int, Float64}, T2 <: Union{Int, Float64}} =
            Coordinate(convert(coordinate_value_type(), x),
                       convert(coordinate_value_type(), y))
coordinate_type(::Type{T}) where {T <: PnmlType} = Coordinate{coordinate_value_type(T)}
coordinate_value_type() = Dec32
coordinate_value_type(::Type) = Dec32
Base.eltype(::Coordinate{T}) where {T} = T
x(c::Coordinate) = c.x
y(c::Coordinate) = c.y
Base.:(==)(l::Coordinate, r::Coordinate) = x(l) == x(r) && y(l) == y(r)

function Base.show(io::IO, c::Coordinate)
    #compact = get(io, :compact, false)::Bool
    print(io, "Coordinate(", c.x, ", ", c.y, ")")
end

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

function Base.show(io::IO, fill::Fill)
    print(io, "Fill(")
    show(io, fill.color); print(io, ", ")
    show(io, fill.image); print(io, ", ")
    show(io, fill.gradient_color); print(io, ", ")
    show(io, fill.gradient_rotation);
    print(io, ")")
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

function Base.show(io::IO, font::Font)
    print(io, "Font(")
    show(io, font.family); print(io, ", ")
    show(io, font.style); print(io, ", ")
    show(io, font.weight); print(io, ", ")
    show(io, font.size); print(io, ", ")
    show(io, font.rotation); print(io, ", ")
    show(io, font.decoration);
    print(io, ")")
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

function Base.show(io::IO, line::Line)
    print(io, "Font(")
    show(io, line.color); print(io, ", ")
    show(io, line.shape); print(io, ", ")
    show(io, line.style); print(io, ", ")
    show(io, line.width);
    print(io, ")")
end

#-------------------
"""
PNML Graphics can be attached to many parts of PNML models.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct Graphics{T <: coordinate_value_type()}
    #{COORD,FILL,FONT,LINE}
    dimension::Coordinate{T} = Coordinate{T}(one(T), one(T))
    fill::Fill = Fill(; color = "black")
    font::Font = Font(; weight = "black")
    line::Line = Line(; color = "black")
    offset::Coordinate{T} = Coordinate{T}(zero(T), zero(T))
    positions::Vector{Coordinate{T}} = Vector{Coordinate{T}}[] # ordered collection
end

function Base.show(io::IO, g::Graphics)
    print(io, "Graphics(")
    show(io, g.dimension); print(io, ", ")
    show(io, g.fill); print(io, ", ")
    show(io, g.font); print(io, ", ")
    show(io, g.line); print(io, ", ")
    show(io, g.offset); print(io, ", ")
    show(io, g.positions);
    print(io, ")")
end


@kwdef struct ArcGraphics{T <: coordinate_value_type()}
    line::Line = Line(; color = "black")
    positions::Vector{Coordinate{T}} = Vector{Coordinate{T}}[] # ordered collection
end

@kwdef struct NodeGraphics{T <: coordinate_value_type()}
    postion::Coordinate{T} = Coordinate{T}()
    dimension::Coordinate{T} = Coordinate(one(T), one(T))
    line::Line = Line(; color = "black")
    fill::Fill = Fill(; color = "black")
end

@kwdef struct AnnotationGraphics{T <: coordinate_value_type()}
    fill::Fill = Fill(; color = "black")
    offset::Coordinate{T} = Coordinate{T}(zero(T), zero(T))
    line::Line = Line(; color = "black")
    font::Font = Font(; weight = "black")
end

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

Parse ToolInfo content.
"""
function tokengraphics_content(node, pntd)
[PNML.Parser.parse_tokengraphics(EzXML.firstelement(node), pntd)]
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
    _positions = Coordinate[]
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
    Graphics{eltype(Coordinate)}(; pairs(args)...)
end

"Add XMLNode attribute, value pair to dictionary."
function kw!(args::AbstractDict, node::XMLNode, key::AbstractString)
    sym = Symbol(replace(key, "-" => "_")) # make proper identifier for readibility
    EzXML.haskey(node, key) && (args[sym] = node[key])
end

"""
$(TYPEDSIGNATURES)

Return [`Line`](@ref PnmlGraphics.Line).
"""
function parse_graphics_line(node, pntd)
    check_nodename(node, "line")
    args = Dict()
    for key in ["color", "shape", "style", "width"]
        kw!(args, node, key)
    end
    PnmlGraphics.Line(; pairs(args)...)
end



"""
$(TYPEDSIGNATURES)

Return [`Coordinate`](@ref PnmlGraphics.Coordinate).
Sandard seems to only use integers, we also allow real numbers.
"""
function parse_graphics_coordinate(node, pntd)
    nn = EzXML.nodename(node)
    if !(nn=="position" || nn=="dimension" || nn=="offset" || nn=="tokenposition")
        throw(ArgumentError("element name wrong: $nn"))
    end

    EzXML.haskey(node, "x") || throw(PNML.MalformedException("$nn missing x"))
    EzXML.haskey(node, "y") || throw(PNML.MalformedException("$nn missing y"))

    PnmlGraphics.Coordinate(PNML.number_value(eltype(Coordinate), node["x"]),
                            PNML.number_value(eltype(Coordinate), node["y"]))
end

"""
$(TYPEDSIGNATURES)

Return [`Fill`](@ref PnmlGraphics.Fill)
"""
function parse_graphics_fill(node, pntd)
    check_nodename(node, "fill")
    args = Dict{Symbol,Union{String,SubString{String}}}()
    for key in ["color", "image", "gradient-color", "gradient-rotation"]
        kw!(args, node, key)
    end
    PnmlGraphics.Fill(; args...)
end

"""
$(TYPEDSIGNATURES)

Return [`Font`](@ref PnmlGraphics.Font).
"""
function parse_graphics_font(node, pntd)
    check_nodename(node, "font")
    args = Dict()
    for key in ["weight", "style", "align", "decoration", "family", "rotation", "size"]
         kw!(args, node, key)
    end
    PnmlGraphics.Font(; pairs(args)...)
end

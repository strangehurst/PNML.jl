# Show methods for the intermediate representation.
# References:
#  - base/show.jl
#  - ?show
#
#
# TODO: use  MIME"application/vnd.julia-vscode.diagnostics" for runtime diagnostics
#
import PrettyPrinting: quoteof

"Indention increment."
const indent_width = 4

"Return string of current indent size in `io`."
indent(io::IO) = repeat(' ', get(io, :indent, 0))

"Increment the `:indent` value by `indent_width`."
inc_indent(io::IO) = IOContext(io, :indent => get(io, :indent, 0) + indent_width)

#-------------------
function Base.show(io::IO, fill::Fill)
    compact = get(io, :compact, false)
    if compact
        print(io, "(", fill.color, ",",
              fill.image, ",",
              fill.gradient_color, ",",
              fill.gradient_rotation, ")")
    else
        print(io, "Fill(color=", fill.color,
              ", image=", fill.image,
              ", gradient-color=", fill.gradient_color,
              ", gradient-rotatio=", fill.gradient_rotation,
              ")")
    end
end

function Base.show(io::IO, ::MIME"text/plain", fill::Fill)
    pprint(IOContext(io, :displaysize => (24, 100)), fill) #show(io, fill)
end

quoteof(f::Fill) = :(Fill($(quoteof(f.color)), 
        $(quoteof(f.image)), 
        $(quoteof(f.gradient_color)),
        $(quoteof(fieldoffset.gradient_rotation))))

#-------------------
function Base.show(io::IO, font::Font)
    print(io,
          "Font(family=", font.family,
          ", style=", font.style,
          ", weight=", font.weight,
          ", size=", font.size,
          ", aligh=", font.align,
          ", rotation=", font.rotation,
          ", decoration=", font.decoration,
          ")")
end

function Base.show(io::IO, ::MIME"text/plain", font::Font)
    show(io, font)
end

#-------------------
function Base.show(io::IO, line::Line)
    print(io,
          "Line(color=", line.color,
          ", style=", line.style,
          ", shape=", line.shape,
          ", width=", line.width,
          ")")
end

function Base.show(io::IO, ::MIME"text/plain", line::Line)
    print(io, line)
end

#-------------------
function Base.show(io::IO, c::Coordinate)
    compact = get(io, :compact, false)
    print(io, "(", c.x, ",", c.y, ")")
end

function Base.show(io::IO, ::MIME"text/plain", c::Coordinate)
    print(io, c)
end

#-------------------
function Base.show(io::IO, g::Graphics)
    compact = get(io, :compact, false)
    print(io, "Graphics(",
          "dimension=", g.dimension,
          ", fill=",      g.fill,
          ", font=",      g.font,
          ", line=",      g.line,
          ", offset=",    g.offset,
          ", position=",  g.position, ")")
end

#-------------------
function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    show(io, MIME"text/plain"(), labelvector)
end
function Base.show(io::IO, mime::MIME"text/plain", labelvector::Vector{PnmlLabel})
    print(io, indent(io), typeof(labelvector), "[")
    io = inc_indent(io)
    for (i,label) in enumerate(labelvector)
        i > 1 && print(io, indent(io))
        #print(io, label)
        show(io, label)
        i < length(labelvector) && print(io, "\n")
    end
    print(io, "]")
    
end

function Base.show(io::IO, label::PnmlLabel)
    #show(IOContext(io, :typeinfo=>Dict), label.dict)
    pprint(IOContext(io, :displaysize => (24, 100)), label) 
end

function Base.show(io::IO, mime::MIME"text/plain", label::PnmlLabel)
    #print(io, "SML:", typeof(label), " ")
    #show(IOContext(io, :typeinfo=>Dict), mime, label.dict)
    pprint(io, label)
end

quoteof(l::PnmlLabel) = :(PnmlLabel($(quoteof(l.tag)), $(quoteof(l.dict))))

#-------------------
function Base.show(io::IO, elvector::Vector{AnyElement})
    show(io, MIME"text/plain"(), elvector)
end
function Base.show(io::IO, mime::MIME"text/plain", elvector::Vector{AnyElement})
    print(io, "SLV:", typeof(elvector), "[")
    io = inc_indent(io)
    for (i,el) in enumerate(elvector)
        print(io, "\n", indent(io), "$i: ")
        pprint(IOContext(io, :displaysize => (24, 100)), el)
        #show(io, mime, el)
        #i < length(elvector) && 
        #print(io, "\n")
    end
    print(io, "]")
end

function Base.show(io::IO, el::AnyElement) #TODO Make parametric.
    #print(io, "SL:", typeof(el), " ")
    pprint(IOContext(io, :displaysize => (24, 100)), el.dict)
    #show(IOContext(io, :typeinfo=>Dict), MIME"text/plain"(), el.dict)
end

function Base.show(io::IO, mime::MIME"text/plain", el::AnyElement) #TODO Make parametric.
    print(io, "SL:", typeof(el), " ")
    pprint(IOContext(io, :displaysize => (24, 100)), el.dict)
    #show(IOContext(io, :typeinfo=>Dict), mime, el.dict)
end

#-------------------
Base.summary(io::IO, ti::ToolInfo) = print(io, summary(ti))
function Base.summary(ti::ToolInfo)
    string(typeof(ti), " name ", ti.toolname, ", version ", ti.version,
           ", ", length(ti.infos), " infos")
end

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    for (i, ti) in enumerate(toolvector)
        print(io, "\n", indent(io), "$i: ")
        show(io, MIME"text/plain"(), ti)
        #i < length(toolvector) && print(io, "\n")
    end
end

function Base.show(io::IO, ti::ToolInfo)
    println(io, summary(ti), ":")
    io = inc_indent(io)
    for (i,info) in enumerate(ti.infos)
        print(io, indent(io))
        show(io, MIME"text/plain"(), info)
        i < length(ti.infos) && print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", ti::ToolInfo)
    show(io, ti)
end
function Base.show(io::IO, ::MIME"text/plain", toolvector::Vector{ToolInfo})
    show(io, toolvector)
end

#-------------------
function Base.show(io::IO, tg::TokenGraphics)
    print(io, "positions: ", tg.positions)
end

function Base.show(io::IO, ::MIME"text/plain", tg::TokenGraphics)
    print(io, tg)
end

#-------------------
function Base.show(io::IO, name::Name)
    print(io, typeof(name), " '", name.text, "'")
    !isnothing(name.graphics) && print(io, ", has graphics")
    !isnothing(name.tools)    && print(io, ", ", length(name.tools), " tool info")
end
function Base.show(io::IO, ::MIME"text/plain", name::Name)
    print(io, name)
end

#-------------------
Base.summary(io::IO, oc::ObjectCommon) = print(io, summary(oc))
function Base.summary(oc::ObjectCommon)
    string("name: ",
           isnothing(oc.name)  ? nothing : oc.name,
           isnothing(oc.graphics) ? ", no graphics, " : ", has graphics, ",
           isnothing(oc.tools)  ? 0 : length(oc.tools),  " tools, ",
           isnothing(oc.labels) ? 0 : length(oc.labels), " labels")
           #TODO xml state
end

function Base.show(io::IO, oc::ObjectCommon)
    io = inc_indent(io)
    if !isnothing(oc.graphics) || !isnothing(oc.tools) || !isnothing(oc.labels)
        print(io, ", ")
    end
    if !isnothing(oc.graphics)
        print(io, "graphics: ", oc.graphics)
    end
    if !isnothing(oc.tools)
        println(io, "\n", indent(io), "tools:")
        show(inc_indent(io), MIME"text/plain"(), oc.tools)
    end
    if !isnothing(oc.labels)
        println(io, "\n", indent(io), "labels:")
        show(inc_indent(io), MIME"text/plain"(), oc.labels)
    end
    # In general, do not display/print the XML.
end

"Prepend comma-space to non-empty `ObjectCommon`."
function show_common(io::IO, x::Union{PnmlNet, PnmlObject, AbstractLabel})
    isempty(x.com) && return
    print(io, ", ")
    show(io, MIME"text/plain"(), x.com )
end

#---------------------------------------------------------------------------------
Base.summary(io::IO, place::Place)  = summary(io, summary(place))
function Base.summary(place::Place)
    string(typeof(place))
end

function Base.show(io::IO, place::Place)
    print(io, summary(place),
          " id ", place.id,
          ", type ", place.sorttype,
          ", marking ", place.marking)
    show_common(io, place)
end

function Base.show(io::IO, ::MIME"text/plain", place::Place)
    show(io, place)
end
function Base.show(io::IO, ::MIME"text/plain", placevector::Vector{Place})
    show(io, placevector)
end

function Base.show(io::IO, placevector::Vector{Place})
    isempty(placevector) && return
    for (i,place) in enumerate(placevector)
        print(io, indent(io), place)
        i < length(placevector) && print(io, "\n")
    end
end

#-------------------
function Base.show(io::IO, trans::Transition)
    print(io, typeof(trans),
          " id ", trans.id, ", condition ", trans.condition)
    show_common(io, trans)
end

function Base.show(io::IO, ::MIME"text/plain", transvector::Vector{Transition})
    show(io, transvector)
end

function Base.show(io::IO, transvector::Vector{Transition})
    for (i,trans) in enumerate(transvector)
        print(io, indent(io), trans)
        i < length(transvector) && print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", trans::Transition)
    show(io, trans)
end

#-------------------
#TODO Make RefPlace, RefTransition an Abstract Type
function Base.show(io::IO, ::MIME"text/plain", r::ReferenceNode)
    #@show "mime ref node"
    show(io, r)
end
function Base.show(io::IO, r::ReferenceNode)
    #@show "ref node"
    print(io, typeof(r), " (id ", pid(r), ", ref ", refid(r))
    show_common(io, r)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", rvector::Vector{<:ReferenceNode})
    #@show "mime vector ref node"
    show(io, rvector)
end
function Base.show(io::IO, rvector::Vector{<:ReferenceNode})
    #@show "vector ref node"
    for (i,r) in enumerate(rvector)
        print(io, indent(io), r)
        i < length(rvector) && print(io, "\n")
    end
end

#function Base.show(io::IO, r::RefTransition)
#    print(io, typeof(r), " (id ", pid(r), ", ref ", ref(r))
#    show_common(io, r.com)
#    print(io, ")")
#end

#function Base.show(io::IO, ::MIME"text/plain", rtvector::Vector{RefTransition})
#    show(io, rtvector)
#end

#function Base.show(io::IO, ::MIME"text/plain", rpvector::Vector{RefPlace})
#    for (i,rp) in enumerate(rpvector)
#        print(io, indent(io), rp)
#        i < length(rpvector) && print(io, "\n")
#    end
#end

#function Base.show(io::IO, ::MIME"text/plain", reft::RefTransition)
#    show(io, reft)
#end

#-------------------
function Base.show(io::IO, arc::Arc)
    #@show Base.StackTraces.stacktrace()
    print(io, typeof(arc), " id ", arc.id,
          ", source: ", arc.source,
          ", target: ", arc.target,
          ", inscription: ", arc.inscription)
    show_common(io, arc)
end
function Base.show(io::IO, ::MIME"text/plain", arcvector::Vector{Arc})
    for (i,arc) in enumerate(arcvector)
        print(io, indent(io), arc)
        i < length(arcvector) && print(io, "\n")
    end
end
function Base.show(io::IO, ::MIME"text/plain", arc::Arc)
    show(io, arc)
end

#-------------------
Base.summary(io::IO, page::Page) = print(io, summary(page))
function Base.summary( page::Page)
    string(typeof(page)," id ", page.id, ", ",
           length(page.places), " places, ",
           length(page.transitions), " transitions, ",
           length(page.arcs), " arcs, ",
           isnothing(declarations(page)) ? 0 : length(declarations(page)), " declarations, ",
           length(page.refPlaces), " refP, ",
           length(page.refTransitions), " refT, ",
           length(page.subpages), " subpages, ",
           summary(page.com)
           )
end

function show_page_field(io::IO, label::AbstractString, x)
    println(io, indent(io), label)
    if !isnothing(x) && length(x) > 0
        show(inc_indent(io), MIME"text/plain"(), x)
        print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", p::Page)
    show(io, p)
end
function Base.show(io::IO, page::Page)
    #TODO Add support for :trim and :compact
    println(io, indent(io), summary(page))
    # Start indent here. Will indent subpages.
    inc_io = inc_indent(io)

    show_page_field(inc_io, "places:",         places(page))
    show_page_field(inc_io, "transitions:",    transitions(page))
    show_page_field(inc_io, "arcs:",           arcs(page))
    show_page_field(inc_io, "declaration:",    declarations(page))
    show_page_field(inc_io, "refPlaces:",      refplaces(page))
    show_page_field(inc_io, "refTransitions:", reftransitions(page))
    show_common(io, page)
    show_page_field(inc_io, "subpages:",       pages(page))
end

function Base.show(io::IO, ::MIME"text/plain", pages::Vector{Page})
    show(io, pages)
end
function Base.show(io::IO, pages::Vector{Page})
    isempty(pages) && return
    for (i,page) in enumerate(pages)
        show(io, MIME"text/plain"(), page)
        i < length(pages) && print(io, "\n")
    end
end

#-------------------
Base.summary(io::IO, net::PnmlNet) = print(io, summary(net))
function Base.summary(net::PnmlNet)
    string( typeof(net), " id ", pid(net), " type ", nettype(net), ", ",
            length(pages(net)), " pages ",
            length(declarations(net)), " declarations ",
            summary(net.com))
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    println(io, summary(net))
    iio = inc_indent(io) # Indent any declarations.
    foreach(declarations(net)) do decl
        print(iio, indent(io))
        show(iio, MIME"text/plain"(), decl)
        println(iio, "\n") 
    end
    show_common(io, net)
    show(io, pages(net))
end

function Base.show(io::IO, ::MIME"text/plain", net::PnmlNet)
    show(io, net)
end

#-------------------
Base.summary(io::IO, pnml::PnmlModel) = print(io, summary(pnml))
function Base.summary(pnml::PnmlModel)
    string(typeof(pnml), " model with ",  length(nets(pnml)), " nets" )
end

# No indent done here.
function Base.show(io::IO, pnml::PnmlModel)
    println(io, summary(pnml))
    println(io, "namespace = ", namespace(pnml))
    for (i, net) in enumerate(nets(pnml))
        show(io, MIME"text/plain"(), net)
        if i < length(nets(pnml))
            print(io, "\n")
        end
    end
    # Omit display of any xml
end

function Base.show(io::IO, ::MIME"text/plain", pnml::PnmlModel)
    return show(io, pnml)
end


#-------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------

#-------------------
Base.summary(io::IO, ptm::PTMarking)  = summary(io, summary(ptm))
function Base.summary(ptm::PTMarking)
    string(typeof(ptm))
end

function Base.show(io::IO, ptm::PTMarking)
    print(io, summary(ptm), " value: ", ptm.value)
    show_common(io, ptm)
end

function Base.show(io::IO, ::MIME"text/plain", ptm::PTMarking)
    show(io, ptm)
end

#-------------------
Base.summary(io::IO, hlm::HLMarking) = summary(hlm)
function Base.summary(hlm::HLMarking)
    string(typeof(hlm))
end

function Base.show(io::IO, hlm::HLMarking)
    print(io, "'", hlm.text, "', ", hlm.term)
    show_common(io, hlm)
end

function Base.show(io::IO, ::MIME"text/plain", hlm::HLMarking)
    show(io, hlm)
end

#-------------------
function Base.show(io::IO, cond::Condition)
    print(io, typeof(cond), " '", cond.text, "', ", cond.term)
    show_common(io, cond)
end

function Base.show(io::IO, ::MIME"text/plain", cond::Condition)
    show(io, cond)
end

#-------------------
function Base.show(io::IO, inscription::PTInscription)
    print(io, typeof(inscription), " value ", inscription.value)
    show_common(io, inscription)
end
function Base.show(io::IO, ::MIME"text/plain", inscription::PTInscription)
    show(io, inscription)
end

#-------------------
function Base.show(io::IO, inscription::HLInscription)
    print(io, typeof(inscription),  " '", inscription.text, "', ", inscription.term)
    show_common(io, inscription)
end
function Base.show(io::IO, ::MIME"text/plain", inscription::HLInscription)
    show(io, inscription)
end


function Base.show(io::IO, declarations::Vector{AbstractDeclaration})
    iio = inc_indent(io)
    print(io, indent(io), typeof(declarations), "[")
    
    for (i,dec) in enumerate(declarations)
        print(iio, "\n", indent(iio))
        show(inc_indent(io), MIME"text/plain"(), dec)
        #i < length(declarations) && print(io, "\n")
    end
    print(io, "]")
end
#function Base.show(io::IO, declare::AbstractDeclaration)
#    print(io, declare)
#end
function Base.show(io::IO, mime::MIME"text/plain", declare::AbstractDeclaration)
    print(io, declare)
    #show(io, mime, declare.label)
    #show(io, mime, declare.com)
end

#-------------------
function Base.show(io::IO, nsorts::Vector{NamedSort})

    print(io, typeof(nsorts), "[")
    for (i,dec) in enumerate(nsorts)
        print(io, "\n", indent(io))
        show(inc_indent(io), MIME"text/plain"(), dec)
        i < length(nsorts) && print(io, "\n")
    end
    print(io, "]")
end
#function Base.show(io::IO, declare::AbstractDeclaration)
#    print(io, declare)
#end
function Base.show(io::IO, mime::MIME"text/plain", nsort::NamedSort)
    #print(io, typeof(nsort), " id=", pid(nsort), " name=", nsort.name, " def=")
    #show(io, mime, nsort.def)
    #pprint(io, nsort)
    pprint(IOContext(io, :displaysize => (24, 180)), nsort)
end

quoteof(n::NamedSort) = :(NamedSort($(quoteof(n.id)), $(quoteof(n.name)), $(quoteof(n.def))))
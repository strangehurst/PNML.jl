using PNML, EzXML
using AbstractTrees, Test
using PrettyPrinting
using IfElse
# Run the tests embedded in docstrings.
using Documenter, LabelledArrays

using PNML: PNML,
    parse_pnml, parse_str, parse_file, parse_node, @xml_str,
    parse_net, parse_page, parse_place, parse_transition, parse_arc,
    parse_refPlace, parse_refTransition,
    parse_toolspecific, parse_graphics, parse_structure,
    parse_initialMarking, parse_hlinitialMarking,
    parse_inscription, parse_hlinscription,
    parse_condition,
    parse_declaration, parse_sort, parse_term, parse_label,
    parse_tokengraphics, parse_tokenposition, parse_name

using PNML: tag, xmlnode, Maybe,
    pid, place_ids, transition_ids, arc_ids,
    reftransition_ids, refplace_ids,
    nets, pages, places, transitions, arcs,
    place, transition, arc,
    has_place, has_transition, has_arc,
    first_net, firstpage,
    tools, has_tools, get_toolinfo,
    marking, condition, conditions, inscription,
    AnyElement, ToolInfo


const GROUP        = get(ENV, "GROUP", "All")
const PRINT_PNML::Bool   = get(ENV, "PRINT_PNML", "true") == "true"
const VERBOSE_PNML::Bool = get(ENV, "VERBOSE_PNML", "true") == "true"

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

const testdir = dirname(@__FILE__)
const pnml_dir = joinpath(@__DIR__, "data")

"Turn string into XML node."
to_node(s::AbstractString) = root(EzXML.parsexml(s))

"Print `node` prepended by optional label string."
function printnode(io::IO, node; label=nothing, kw...)
    if PRINT_PNML
        !isnothing(label) && print(io, label, " ")
        show(io, MIME"text/plain"(), node) 
        println(io, "\n")
    end
end
function printnode(n; kw...)
    printnode(stdout, n; kw...)
end

function printnodeln(io::IO, n; kw...)
    printnode(io, n; kw...)
    PRINT_PNML && println(io)
end

header(s) = if VERBOSE_PNML
    println("##### ", s)
end

const SHOW_SUMMARYSIZE = get(ENV, "SHOW_SUMMARYSIZE", "false") == "true"
function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

"Return true if one of the GROUP environment variable's values if found in 'v'."
select(v...) = any(any(==(g), v) for g in split(GROUP))

if select("None")
    return
end

@testset verbose=false "PNML.jl" begin
    if select("All", "Doc")
        header("Doctests")
        @testset "doctest" begin doctest(PNML, manual = true) end
    end
    if select("All", "Base")
        header("Base")
        @testset "maps"         begin include("maps.jl") end
        @testset "utils"        begin include("utils.jl") end
    end
    if select("All", "IR")
        header("IR")
        @testset "nodes"        begin include("nodes.jl") end
        @testset "labels"       begin include("labels.jl") end
        @testset "graphics"     begin include("graphics.jl") end
        @testset "parse_labels" begin include("parse_labels.jl") end
        @testset "toolspecific" begin include("toolspecific.jl") end
        @testset "exceptions"   begin include("exceptions.jl") end
        @testset "parse_tree"   begin include("parse_tree.jl") end
        @testset "pages"        begin include("pages.jl") end
        @testset "flatten"      begin include("flatten.jl") end
        @testset "example file" begin include("parse_examples.jl") end
    end
    if select("All", "Net")
        header("Net")
        @testset "document"     begin include("document.jl") end
        @testset "simplenet"    begin include("simplenet.jl") end
    end
end

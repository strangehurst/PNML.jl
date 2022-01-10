using PNML, EzXML
using AbstractTrees, Test
using PrettyPrinting
using IfElse
# Run the tests embedded in docstrings.
using Documenter, LabelledArrays

using PNML: parse_doc, parse_pnml, @xml_str, pid, tag, xmlnode, Maybe,
    parse_net, parse_page, parse_place, parse_transition, parse_arc,
    parse_refPlace, parse_refTransition,
    parse_toolspecific, parse_graphics, parse_structure,
    parse_initialMarking, parse_hlinitialMarking,
    parse_inscription, parse_hlinscription,
    parse_condition,
    parse_declaration, parse_sort, parse_term, parse_label,
    parse_tokengraphics, parse_tokenposition, parse_name

const GROUP        = get(ENV, "GROUP", "All")
const PRINT_PNML   = get(ENV, "PRINT_PNML", true)
const VERBOSE_PNML = get(ENV, "VERBOSE_PNML", true)

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

const testdir = dirname(@__FILE__)
const pnml_dir = joinpath(@__DIR__, "data")
    
"Turn string into XML node."
to_node(s::AbstractString) = root(EzXML.parsexml(s))

"Pretty print PnmlDict."
function printnode(io::IO, n; label=nothing, compact=false)
    if PRINT_PNML
        print(io, typeof(n), " ")
        !isnothing(label) && print(io, label, " ")
        pprint(io, n)
        !compact && println(io, "")
    end
end
function printnode(n; label=nothing, compact=false)
    printnode(stdout, n; label, compact)
end
function printnodeln(n; label=nothing, compact=false)
    printnodeln(stdout, n; label, compact)
end

function printnodeln(io::IO, n; label=nothing, compact=false)
    printnode(io, n; label, compact)
    PRINT_PNML && println(io)
end


header(s) = if VERBOSE_PNML
    println("##### ", s)
end

const SHOW_SUMMARYSIZE = haskey(ENV, "SHOW_SUMMARYSIZE") ? lowercase(ENV["SHOW_SUMMARYSIZE"]) == "true" : true
function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

"Return true if one of the GROUP environment variable's values if found in 'v'."
select(v...) = any(any(==(g), v) for g in split(GROUP))

if !select("None")
    @testset verbose=false "PNML.jl" begin
        header("TOP LEVEL UNIT TEST")
        if select("All", "Doc")
            header("Doctests")
            @testset "doctest" begin doctest(PNML, manual = true) end 
        end     
        if select("All", "IR")
            header("IR")
            @testset "maps"     begin include("maps.jl") end
            @testset "utils"    begin include("utils.jl") end
            @testset "print"    begin include("print.jl") end
            @testset "parse_labels" begin include("parse_labels.jl") end
            @testset "pages"    begin include("pages.jl") end
            @testset "parse_tree"   begin include("parse_tree.jl") end
            @testset "toolspecific" begin include("toolspecific.jl") end
            @testset "graphics"     begin include("graphics.jl") end
            @testset "exceptions"   begin include("exceptions.jl") end
            @testset "example pnml" begin include("parse_examples.jl") end
            @testset "attribute" begin
                header("UNCLAIMED ELEMENT")
                # pnml attribute XML nodes do not have display/GUI data and other
                # overhead of pnml annotation nodes. Both are pnml labels.
                a = PNML.unclaimed_element(xml"""
                   <declarations atag="test">
                        <something> some content </something>
                        <something2 tag2="two"> <value/> </something2>
                   </declarations>
                """; reg=PNML.IDRegistry())
                printnode(a)
                @test !isnothing(a)
            end
        end
        if select("All", "Net")
            header("Net")
            @testset "document"     begin include("document.jl") end
            @testset "simplenet"    begin include("simplenet.jl") end
        end
    end
end # select none

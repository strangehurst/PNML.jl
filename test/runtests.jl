using PNML, EzXML, IfElse, AbstractTrees, Test, PrettyPrinting
# Run the tests embedded in docstrings.
using Documenter, LabelledArrays

using PNML: parse_doc, parse_pnml, @xml_str,
    parse_net, parse_page, parse_place, parse_transition, parse_arc,
    parse_refPlace, parse_refTransition,
    parse_toolspecific, parse_graphics, parse_structure,
    parse_initialMarking, parse_hlinitialMarking,
    parse_inscription, parse_hlinscription,
    parse_condition,
    parse_declaration, parse_sort, parse_term, parse_label,
    parse_tokengraphics, parse_tokenposition, parse_name

const GROUP = get(ENV, "GROUP", "All")
const testdir = dirname(@__FILE__)
const pnml_dir = joinpath(@__DIR__, "data")
    
# Turn string into a PnmlDict representing XML node.
to_node(s) =  root(EzXML.parsexml(s))

"Default is to NOT print during test."
const PRINT_PNML = haskey(ENV, "PRINT_PNML") ? lowercase(ENV["PRINT_PNML"]) == "true" : false
function printnode(n; label=nothing, compress=true, compact=false)
    if PRINT_PNML
        !isnothing(label) && print(label, " ")
        pprintln(compress ? PNML.compress(n) : n)
        !compact && println()
    end
end

const SHOW_SUMMARYSIZE = haskey(ENV, "SHOW_SUMMARYSIZE") ? lowercase(ENV["SHOW_SUMMARYSIZE"]) == "true" : true
function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

"Return true if the GROUP environment variable's value if found in 'v'."
select(v...) = any(==(GROUP), v)

if !select("None")
@testset "PNML.jl" begin
    if select("All", "Doc")
        @testset "doctest" begin doctest(PNML, manual = false) end 
    end     
    @testset "maps"     begin include("maps.jl") end
    @testset "utils"    begin include("utils.jl") end
    @testset "print"    begin include("print.jl") end
    @testset "parse_tree"   begin include("parse_tree.jl") end
    @testset "parse_labels" begin include("parse_labels.jl") end
    @testset "toolspecific" begin include("toolspecific.jl") end
    @testset "graphics"     begin include("graphics.jl") end
    @testset "exceptions"   begin include("exceptions.jl") end
    @testset "example pnml" begin include("parse_examples.jl") end
    @testset "attribute" begin
        # pnml attribute XML nodes do not have display/GUI data and other
        # overhead of pnml annotation nodes. Both are pnml labels.
        a = PNML.attribute_elem(xml"""
           <declarations atag="test">
                <something> some content </something>
                <something2 tag2="two"> <value/> </something2>
           </declarations>
        """; reg=PNML.IDRegistry())
        printnode(a)
        @test !isnothing(a)
        #TODO more tests
    end
    @testset "document"     begin include("document.jl") end
    @testset "simplenet"    begin include("simplenet.jl") end
end
end

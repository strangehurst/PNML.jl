using PNML, EzXML, IfElse, AbstractTrees, Test, PrettyPrinting

using PNML: parse_doc, parse_pnml, @xml_str,
    parse_net, parse_page, parse_place, parse_transition, parse_arc,
    parse_refPlace, parse_refTransition,
    parse_toolspecific, parse_graphics, parse_structure,
    parse_initialMarking, parse_hlinitialMarking,
    parse_inscription, parse_hlinscription,
    parse_condition,
    parse_declaration, parse_sort, parse_term, parse_label,
    parse_tokengraphics, parse_tokenposition, parse_name

to_node(s) =  root(EzXML.parsexml(s))

"Default is to NOT print during test."
const PRINT_PNML = haskey(ENV, "PRINT_PNML") ? lowercase(ENV["PRINT_PNML"]) == "true" : false
function printnode(n; label=nothing)
    if PRINT_PNML
        !isnothing(label) && print(label, " ")
        pprint(n)
        println()
    end
end

const SHOW_SUMMARYSIZE = haskey(ENV, "SHOW_SUMMARYSIZE") ? lowercase(ENV["SHOW_SUMMARYSIZE"]) == "true" : true
function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

@testset "attribute" begin
    n = xml"""
       <declarations atag="test">
            <something> #TODO </something>
            <something2 tag2="two"> <value/> </something2>
       </declarations>
        """
    a = PNML.attribute_elem(n)
    printnode(a)
    @test !isnothing(a)
end

if true
@testset "PNML.jl" begin
    @testset "maps"     begin include("maps.jl") end
    @testset "utils"    begin include("utils.jl") end
    @testset "print"    begin include("print.jl") end
    @testset "parse_tree"   begin include("parse_tree.jl") end
    @testset "parse_labels" begin include("parse_labels.jl") end
    @testset "toolspecific" begin include("toolspecific.jl") end
    @testset "graphics"     begin include("graphics.jl") end
    @testset "exceptions"   begin include("exceptions.jl") end
    @testset "example pnml" begin include("parse_examples.jl") end
    @testset "document"     begin include("document.jl") end
end
end

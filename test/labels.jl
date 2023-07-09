using PNML, EzXML, ..TestUtils, JET, PrettyPrinting, NamedTupleTools, AbstractTrees
using PNML:
    Maybe, tag, xmlnode, XMLNode, xmlroot, labels,
    unclaimed_label, anyelement, PnmlLabel, AnyElement,
    has_label, get_label, get_labels, add_label!,
    default_marking, default_inscription, default_condition, default_sort,
    default_term, default_one_term, default_zero_term,
    has_graphics, graphics, has_name, name, has_label,
    value, common, tools, graphics, labels,
    parse_initialMarking, parse_inscription, parse_text

const pntd::PnmlType = PnmlCoreNet()
const noisy::Bool = false

@testset "ObjectCommon" begin
    oc = @inferred PNML.ObjectCommon()

    @test isnothing(PNML.graphics(oc))
    @test isempty(PNML.tools(oc))
    @test isempty(PNML.labels(oc))

    oc = @inferred PNML.ObjectCommon(nothing, PNML.ToolInfo[], PNML.PnmlLabel[])
    @test isnothing(PNML.graphics(oc))
    @test isempty(PNML.tools(oc))
    @test isempty(PNML.labels(oc))
end

@testset "PT initMarking" begin
    node = xml"""
    <initialMarking>
        <text>123</text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics>
                <tokenposition x="6" y="9"/>
            </tokengraphics>
        </toolspecific>
    </initialMarking>
    """

    mark = parse_initialMarking(node, pntd, registry())
    @test typeof(mark) <: PNML.Marking
    @test typeof(value(mark)) <: Union{Int,Float64}
    @test value(mark) == mark()
    @test value(mark) == 123
    noisy && @show mark

    mark1 = PNML.Marking(23)
    #@report_opt PNML.Marking(2)
    @test_call PNML.Marking(23)
    @test typeof(mark1()) == typeof(23)
    @test mark1() == 23
    @test value(mark1) == 23
    #@report_opt mark1()
    @test_call mark1()

    @test (graphics ∘ common)(mark1) === nothing
    @test (tools ∘ common)(mark1) === nothing || isempty((tools ∘ common)(mark1))
    @test (labels ∘ common)(mark1) === nothing || isempty((labels ∘ common)(mark1))

    mark2 = PNML.Marking(3.5)
    @test_call PNML.Marking(3.5)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()

    @test (graphics ∘ common)(mark2) === nothing
    @test (tools ∘ common)(mark2) === nothing || isempty((tools ∘ common)(mark2))
    @test (labels ∘ common)(mark2) === nothing || isempty((labels ∘ common)(mark2))

    mark3 = PNML.Marking()
    @test_call PNML.Marking()
    @test typeof(mark3()) == typeof(default_marking(PnmlCoreNet())())
    @test mark3() == default_marking(PnmlCoreNet())()
    @test_call mark3()

    @test (graphics ∘ common)(mark3) === nothing
    @test (tools ∘ common)(mark3) === nothing || isempty((tools ∘ common)(mark3))
    @test (labels ∘ common)(mark3) === nothing || isempty((labels ∘ common)(mark3))
end

@testset "PT inscription" begin
    n1 = xml"<inscription> <text> 12 </text> </inscription>"
    inscription = parse_inscription(n1, pntd, registry())
    @test inscription isa PNML.Inscription
    noisy && @show inscription
    @test value(inscription) == 12
    @test (graphics ∘ common)(inscription) === nothing
    @test (tools ∘ common)(inscription) === nothing || isempty((tools ∘ common)(inscription))
    @test (labels ∘ common)(inscription) === nothing || isempty((labels ∘ common)(inscription))
end

@testset "text" begin
    str1 = """<text>ready</text>"""
    n = parse_text(xmlroot(str1), pntd, registry())
    @test n == "ready"

    str2 = """
<text>
ready
</text>
    """
    n = parse_text(xmlroot(str2), pntd, registry())
    @test n == "ready"

    str3 = """
 <text>    ready  </text>
    """
    n = parse_text(xmlroot(str3), pntd, registry())
    @test n == "ready"

    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_text(xmlroot(str4), pntd, registry())
    @test n == "ready\nto\ngo"
end

@testset "labels" begin
    lab = PnmlLabel[]
    reg = registry()

    for i in 1:4 # add 4 labels
        x = i < 3 ? 1 : 2 # make 2 tagnames
        node = xmlroot("<test$x> $i </test$x>")
        @test_call target_modules = (PNML,) add_label!(lab, node, PnmlCoreNet(), reg)
        add_label!(lab, node, PnmlCoreNet(), reg)
    end

    @test length(lab) == 4

    for l in lab
        @test_call tag(l)
        @test tag(l) === :test1 || tag(l) === :test2
        @test xmlnode(l) isa Maybe{EzXML.Node}
        @test xmlnode(l) isa Maybe{XMLNode}
    end

    @test_call has_label(lab, :test1)
    @test_call get_label(lab, :test1)
    @test_call get_labels(lab, :test1)

    @test has_label(lab, :test1)
    @test !has_label(lab, :bumble)

    v = get_label(lab, :test2)
    @test v isa PnmlLabel
    @test v.elements[1].tag === :content
    @test v.elements[1].val == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        v = PNML.get_labels(lab, labeltag) |> collect
        @test length(v) == 2
        for l in v
            @test tag(l) === labeltag
        end
    end
end

@testset "unlaimed structure" begin
    str0 = """<structure><foo/></structure>"""
    @test PNML.parse_node(xmlroot(str0), PnmlCoreNet(), registry()) isa PNML.Structure
end

AbstractTrees.children(a::PNML.AnyXmlNode) = a.val isa Vector{PNML.AnyXmlNode} ? a.val : nothing

AbstractTrees.printnode(io::IO, a::PNML.AnyXmlNode) = print(io, a.tag, "", a.val isa AbstractString && a.val)

function test_unclaimed(xmlstring::String)#, expected::NamedTuple)
    if noisy
        println("\n+++++++++++++++++++")
        println("XML: ", xmlstring)
        #print("expected: "); pprint(expected); println()
        println("-------------------")
    end
    node::XMLNode = xmlroot(xmlstring)
    reg1 = registry()
    reg2 = registry()

    u = unclaimed_label(node, PnmlCoreNet(), reg1)
    l = PnmlLabel(u, node)
    a = anyelement(node, reg2)
    if noisy
        println("u = $(u.first) "); dump(u) #AbstractTrees.print_tree.(u.second) #pprintln(u)
        println("l = $(l.tag) "); dump(l) #AbstractTrees.print_tree.(l.elements)
        println("a = $(a.tag) " ); dump(a) #AbstractTrees.print_tree.(a.elements)
    end

    @test_opt broken=false function_filter=pnml_function_filter target_modules=target_modules unclaimed_label(node, PnmlCoreNet(), reg1)
    @test_opt broken=false PnmlLabel(u, node)
    @test_opt broken=false function_filter=pnml_function_filter target_modules = (PNML,) anyelement(node, reg2)

    @test_call target_modules = (PNML,) unclaimed_label(node, PnmlCoreNet(), reg1)
    @test_call target_modules = (PNML,) PnmlLabel(u, node)
    @test_call target_modules = (PNML,) anyelement(node, reg2)

    @test !isnothing(u)
    @test !isnothing(l)
    @test !isnothing(a)

    @test u isa Pair{Symbol, Vector{PNML.AnyXmlNode}}
    @test l isa PnmlLabel
    @test a isa AnyElement

    let nn = Symbol(nodename(node))
        @test u.first === nn
        @test tag(l) === nn
        @test tag(a) === nn
    end
    @test u.second isa Vector{PNML.AnyXmlNode}
    @test l.elements isa Vector{PNML.AnyXmlNode}
    @test a.elements isa Vector{PNML.AnyXmlNode}
    #! unclaimed id is not registered
    u.second[1].tag === :id    && @test !isregistered(reg1, u.second[1].val)
    return l, a
end

@testset "unclaimed" begin
    noisy && println("## test unclaimed, PnmlLabel, anyelement")

    ctrl = [
        ("""<declarations> </declarations>""", (; :content => "")),

        ("""<declarations atag="atag1"> </declarations>""", (; :atag => "atag1", :content => "")),

        # Tuple{NamedTuple}
        ("""<foo><declarations> </declarations></foo>""",
             (; :declarations => ((; :content => ""),))),

        # no content, no attribute maybe results in empty tuple.
        ("""<null></null>""", (; :content => "")),
        ("""<null2/>""", (; :content => "")),
        # no content, with attribute
        ("""<null at="null"></null>""", (; :at => "null")),
        ("""<null2 at="null2" />""", (; :at => "null2")),
        # empty content, no attribute
        ("""<empty> </empty>""", (; :content => "")),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""", (; :content => "", :at => "empty")),
        # unclaimed do not register id
        ("""<foo id="testid1" />""", (; :id => "testid1", :content => "")),
        ("""<foo id="testid2"/>""", (; :id => "testid2", :content => "")),
        ("""<foo id="repeats">
            <one>ONE</one>
            <one>TWO</one>
            <one>TRI</one>
        </foo>""", (; :id => "repeats", :one => ((content = "ONE",), (content = "TWO",), (content = "TRI",),) )),
    ]

    for (s, expected) in ctrl
        l, a = test_unclaimed(s)#!, expected)
        noisy && println("-------------------")
        #test_elements(l, a, expected)
        #for (key, expected) in pairs(expected); test_elements(l, a, expected); end
    end
    noisy && println()

    s2 = """<declarations atag="atag2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="tagtwo"> <value/> <value tag3="tagthree"/> </something2>
            </declarations>"""
    x = namedtuple([
        :atag => "atag2",
        :something => ((; :content => "some content"), # tuple of named tuples
                       (; :content => "other stuff")),
        :something2 => ((; :tag2 => "tagtwo",
                           :value => ((; :content => ""),
                                      (; :tag3 => "tagthree", :content => "")),
                        ))
    ])

    l, a = test_unclaimed(s2)
    noisy && println("-------------------")
    #test_elements(l, a, x)
    noisy && println("-------------------")
end

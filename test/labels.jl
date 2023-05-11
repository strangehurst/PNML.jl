using PNML, EzXML, ..TestUtils, JET, PrettyPrinting, NamedTupleTools
using PNML:
    Maybe, tag, xmlnode, XMLNode, xmlroot, labels,
    unclaimed_label, anyelement, PnmlLabel, AnyElement,
    has_label, get_label, get_labels, add_label!,
    default_marking, default_inscription, default_condition, default_sort,
    default_term, default_one_term, default_zero_term,
    has_graphics, graphics, has_name, name, has_label,
    value, common, tools, graphics, labels,
    parse_initialMarking, parse_inscription, parse_text

const pntd = PnmlCoreNet()
const noisy::Bool = true

@testset "ObjectCommon" begin
    oc = @inferred PNML.ObjectCommon()
    @test isnothing(PNML.graphics(oc))
    @test isnothing(PNML.tools(oc))
    @test isnothing(PNML.labels(oc))
    d = (; :graphics => nothing, :tools => nothing, :labels => nothing)
    oc = @inferred PNML.ObjectCommon(d)
    # if false
    #     @show typeof(oc)
    #     @show typeof(PNML.graphics(oc))
    #     @show typeof(PNML.tools(oc))
    #     @show typeof(PNML.labels(oc))
    # end
    @test isnothing(PNML.graphics(oc))
    @test isnothing(PNML.tools(oc))
    @test isnothing(PNML.labels(oc))
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
    @test (tools ∘ common)(mark1) === nothing || isempty((tool ∘ common)(mark1))
    @test (labels ∘ common)(mark1) === nothing || isempty((labels ∘ common)(mark1))

    mark2 = PNML.Marking(3.5)
    @test_call PNML.Marking(3.5)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()

    @test (graphics ∘ common)(mark2) === nothing
    @test (tools ∘ common)(mark2) === nothing || isempty((tool ∘ common)(mark2))
    @test (labels ∘ common)(mark2) === nothing || isempty((labels ∘ common)(mark2))

    mark3 = PNML.Marking()
    @test_call PNML.Marking()
    @test typeof(mark3()) == typeof(default_marking(PnmlCoreNet())())
    @test mark3() == default_marking(PnmlCoreNet())()
    @test_call mark3()

    @test (graphics ∘ common)(mark3) === nothing
    @test (tools ∘ common)(mark3) === nothing || isempty((tool ∘ common)(mark3))
    @test (labels ∘ common)(mark3) === nothing || isempty((labels ∘ common)(mark3))
end

@testset "PT inscription" begin
    n1 = xml"<inscription> <text> 12 </text> </inscription>"
    inscription = parse_inscription(n1, pntd, registry())
    @test inscription isa PNML.Inscription
    noisy && @show inscription
    @test value(inscription) == 12
    @test (graphics ∘ common)(inscription) === nothing
    @test (tools ∘ common)(inscription) === nothing || isempty((tool ∘ common)(inscription))
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
    # Exersize the labels of a NamedTuple

    tup = (; :labels => PnmlLabel[])
    reg = registry()
    @test_call labels(tup)
    @test labels(tup) isa Vector{PnmlLabel}

    for i in 1:4 # add 4 labels
        x = i < 3 ? 1 : 2 # make 2 tagnames
        node = xmlroot("<test$x> $i </test$x>")
        @test_call target_modules = (PNML,) add_label!(tup, node, PnmlCoreNet(), reg)
        add_label!(tup, node, PnmlCoreNet(), reg)
        @test length(labels(tup)) == i
        @test tup.labels === labels(tup)
    end

    @test length(tup.labels) == 4
    @test length(labels(tup)) == 4

    for l in labels(tup)
        @test_call tag(l)
        @test tag(l) === :test1 || tag(l) === :test2
        @test xmlnode(l) isa Maybe{EzXML.Node}
        @test xmlnode(l) isa Maybe{XMLNode}
    end

    @test_call has_label(tup, :test1)
    @test_call get_label(tup, :test1)
    @test_call get_labels(tup, :test1)

    @test has_label(tup, :test1)
    @test !has_label(tup, :bumble)

    v = get_label(tup, :test2)
    @test v isa PnmlLabel
    @test v.elements.content == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        v = PNML.get_labels(tup, labeltag)
        @test length(v) == 2
        for l in v
            @test tag(l) === labeltag
        end
    end
end


function test_unclaimed(xmlstring::String)#, funk::NamedTuple)
    if noisy
        println("+++++++++++++++++++")
        println("XML: ", xmlstring)
        #print("funk: "); pprint(funk); println()
        println("-------------------")
    end
    node::XMLNode = xmlroot(xmlstring)
    reg1 = registry()
    reg2 = registry()

    u = unclaimed_label(node, PnmlCoreNet(), reg1)
    l = PnmlLabel(u, node)
    a = anyelement(node, reg2)
    if noisy
        # @show typeof(u) typeof(l) typeof(a)
        print("u = "); pprintln(u)
        print("l = "); pprintln(l)
        print("a = "); pprintln(a)
        end
    # unclaimed_label returns Pair{Symbol,Vector{Pair{Symbol,Any}}}
    # Where the outer symbol is the label name and the vector is the label's contents.
    # function_filter(@nospecialize(ft)) = ft !== typeof(PnmlIDRegistrys.register_id!)

    @test_opt broken=true function_filter=pnml_function_filter target_modules=target_modules unclaimed_label(node, PnmlCoreNet(), reg1)
    @test_opt broken=false PnmlLabel(u, node)
    @test_opt broken=true function_filter=pnml_function_filter target_modules = (PNML,) anyelement(node, reg2)

    @test_call target_modules = (PNML,) unclaimed_label(node, PnmlCoreNet(), reg1)
    @test_call target_modules = (PNML,) PnmlLabel(u, node)
    @test_call target_modules = (PNML,) anyelement(node, reg2)

    @test !isnothing(u)
    @test !isnothing(l)
    @test !isnothing(a)

    @test u isa Pair{Symbol, <:NamedTuple}
    @test l isa PnmlLabel
    @test a isa AnyElement

    let nn = Symbol(nodename(node))
        @test u.first === nn
        @test tag(l) === nn
        @test tag(a) === nn
    end
    @test u.second isa NamedTuple
    @test l.elements isa NamedTuple
    @test a.elements isa NamedTuple
    haskey(u.second, :id) && @test isregistered(reg1, u.second[:id])
    haskey(l.elements, :id) && @test isregistered(reg1, l.elements[:id])
    haskey(a.elements, :id) && @test isregistered(reg2, a.elements[:id])
    #@report_opt isregistered(reg2, :id)
    @test_call isregistered(reg2, :id)

    return l, a
end
ntd(t) = Dict(zip(keys(t), values(t)))

"Compare tuples."
function cmptup(tup, val)
    @assert tup isa NamedTuple
    @assert val isa NamedTuple
    t = convert(Dict, tup)
    v = convert(Dict, val)
    print("tup = "); pprintln(tup)
    print("val = "); pprintln(val)
    #print("t = "); pprintln(t)
    #print("v = "); pprintln(v)
    #return t == v
    for k in keys(val)
        @show k
        if val[k] isa NamedTuple
            if !cmptup(tup[k], val[k])
                @show tup val
                return false
            end
        else
            if tup[k] != val[k]
                @show tup val
                return false
            end
        end
        return true
    end
end

function test_elements(l, a, funk)
    @show keys(funk)
    @test funk isa NamedTuple
    for key in keys(funk)
        @test hasproperty(l.elements, key)
        @test hasproperty(a.elements, key)
    end
    @test cmptup(l.elements, funk)
    @test cmptup(a.elements, funk)
end

@testset "unclaimed" begin
    println("## test unclaimed, PnmlLabel, anyelement")

    ctrl = [
        ("""<declarations> </declarations>""", (; :content => "")),

        ("""<declarations atag="atag1"> </declarations>""", (; :atag => "atag1", :content => "")),

        ("""<foo><declarations> </declarations></foo>""",
             (; :declarations => (; :content => ""))),
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
        ("""<foo id="testid1" />""", (; :id => :testid1, :content => "")),
        ("""<foo id="testid2"/>""", (; :id => :testid2, :content => "")),
    ]

    for (s, funk) in ctrl
        l, a = test_unclaimed(s)#!, funk)
        println("-------------------")
        test_elements(l, a, funk)
        #for (key, val) in pairs(funk); test_elements(l, a, funk); end
    end
    println()

    s2 = """<declarations atag="atag2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="tagtwo"> <value/> <value tag3="tagthree"/> </something2>
            </declarations>"""
    x = namedtuple([:atag => "atag2",
                    :something => [(; :content => "some content"),
                                (; :content => "other stuff")],
                    :something2 => [(; :tag2 => "tagtwo",
                                   :value => [(; :content => ""),
                                              (; :tag3 => "tagthree", :content => "")],
                                )]
                ])

    l, a = test_unclaimed(s2)
    println("-------------------")
    test_elements(l, a, x)
    println("-------------------")
    println("-------------------")
    println("-------------------")

end

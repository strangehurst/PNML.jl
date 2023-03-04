using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, xmlnode, XMLNode, xmlroot, labels,
    unclaimed_label, anyelement, PnmlLabel, AnyElement,
    has_label, get_label, get_labels, add_label!,
    default_marking, default_inscription, default_condition, default_sort,
    default_term, default_one_term, default_zero_term,
    value

@testset "ObjectCommon" begin
    noisy::Bool = false
    oc = @inferred PNML.ObjectCommon()
    if noisy
        @show typeof(oc)
        @show typeof(PNML.graphics(oc))
        @show typeof(PNML.tools(oc))
        @show typeof(PNML.labels(oc))
    end
    d = PnmlDict(:graphics => nothing, :tools => nothing, :labels => nothing)
    oc = @inferred PNML.ObjectCommon(d)
    if noisy
        @show typeof(oc)
        @show typeof(PNML.graphics(oc))
        @show typeof(PNML.tools(oc))
        @show typeof(PNML.labels(oc))
    end
    println()
end

@testset "unclaimed" begin
    # node => [key => value] expected to be in the PnmlDict after parsing node.
    ctrl =
    [
        ("""<declarations> </declarations>""", [:content => ""]),
        ("""<declarations atag="test1"> </declarations>""",
            [:atag => "test1", :content => ""]),
        ("""<declarations atag="test2">
                    <something> some content </something>
                    <something> other stuff </something>
                    <something2 tag2="two"> <value/> <value tag3="three"/> </something2>
                </declarations>""",
            [:atag => "test2",
             :something => [PnmlDict(:content => "some content"),
                            PnmlDict(:content => "other stuff")],
             :something2 => PnmlDict(:value => [PnmlDict(:content => ""),
                                                PnmlDict(:tag3 => "three", :content => "")],
                                        :tag2 => "two")]),
        ("""<foo><declarations> </declarations></foo>""",
            [:declarations => PnmlDict(:content => "")]),
        # no content, no attribute results in empty PnmlDict.
        ("""<null></null>""", []),
        ("""<null2/>""", []),
        # no content, with attribute
        ("""<null at="null"></null>""", [:at => "null"]),
        ("""<null2 at="null2" />""", [:at => "null2"]),
        # empty content, no attribute
        ("""<empty> </empty>""", [:content => ""]),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""", [:content => "", :at => "empty"]),
        ("""<foo id="testid"/>""", [:id => :testid]),
    ]

    noisy::Bool = false
    for (s, funk) in ctrl
        noisy && print("\n", s, "\n")
        node::XMLNode = xmlroot(s)
        reg1 = PnmlIDRegistry()
        reg2 = PnmlIDRegistry()

        u = unclaimed_label(node, PnmlCoreNet(), reg1)
        noisy && @show typeof(u)
        noisy && noisy && @show u
        l = PnmlLabel(u, node)
        noisy && @show l
        a = anyelement(node, reg2)
        noisy && @show a

        function_filter(@nospecialize(ft)) = ft !== typeof(PnmlIDRegistrys.register_id!)

        @test_opt function_filter=pnml_function_filter target_modules=target_modules unclaimed_label(node, PnmlCoreNet(), reg1)
        @test_opt function_filter=function_filter target_modules=(PNML,PnmlCore,) unclaimed_label(node, PnmlCoreNet(), reg1)
        @test_opt PnmlLabel(u, node)
        @test_opt function_filter=function_filter target_modules = (PNML,PnmlCore,) anyelement(node, reg2)

        @test_call unclaimed_label(node, PnmlCoreNet(), reg1) #!
        @test_call PnmlLabel(u, node)
        @test_call anyelement(node, reg2) #!

        @test !isnothing(u)
        @test !isnothing(l)
        @test !isnothing(a)

        @test u isa Pair{Symbol,PnmlDict}
        @test l isa PnmlLabel
        @test a isa AnyElement

        nn = Symbol(nodename(node))
        @test u.first === nn
        @test tag(l) === nn
        @test tag(a) === nn

        @test u.second isa PnmlDict
        @test l.dict isa PnmlDict
        @test a.dict isa PnmlDict

        # test each key,value pair
        for (key, val) in funk
            #@show typeof(key), typeof(val)#@show key#@show val
            @test haskey(u.second, key)
            @test u.second[key] == val
            @test haskey(l.dict, key)
            @test l.dict[key] == val
            @test haskey(a.dict, key)
            @test a.dict[key] == val
        end

        haskey(u.second, :id) && @test isregistered_id(reg1, u.second[:id])
        haskey(l.dict, :id) && @test isregistered_id(reg1, l.dict[:id])
        haskey(a.dict, :id) && @test isregistered_id(reg2, a.dict[:id])
<
        #@report_opt isregistered_id(reg2, :id)
        @test_call isregistered_id(reg2, :id)
    end
end

@testset "PT initMarking" begin
    node = xml"""
    <initialMarking>
        <text>1</text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics>
                <tokenposition x="6" y="9"/>
            </tokengraphics>
        </toolspecific>
    </initialMarking>
    """

    n = parse_node(node, PnmlIDRegistry())
    @test typeof(n) <: PNML.Marking
    #@test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(value(n)) <: Union{Int,Float64}
    @test value(n) == n()

    mark1 = PNML.Marking(2)
    #@report_opt PNML.Marking(2)
    @test_call PNML.Marking(2)
    @test typeof(mark1()) == typeof(2)
    @test mark1() == 2
    #@report_opt mark1()
    @test_call mark1()

    mark2 = PNML.Marking(3.5)
    @test_call PNML.Marking(3.5)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()

    mark3 = PNML.Marking()
    @test_call PNML.Marking()
    @test typeof(mark3()) == typeof(default_marking(PnmlCoreNet())())
    @test mark3() == default_marking(PnmlCoreNet())()
    @test_call mark3()
end

@testset "PT inscription" begin
    n1 = xml"<inscription> <text> 12 </text> </inscription>"
    @testset for node in [n1]
        n = parse_node(node, PnmlIDRegistry())
        @test typeof(n) <: PNML.Inscription
        #@test xmlnode(n) isa Maybe{EzXML.Node}
        @test value(n) == 12
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "text" begin
    str1 = """<text>ready</text>"""
    n = parse_node(xmlroot(str1), PnmlIDRegistry())
    @test n == "ready"

    str2 = """
<text>
ready
</text>
    """
    n = parse_node(xmlroot(str2), PnmlIDRegistry())
    @test n == "ready"

    str3 = """
 <text>    ready  </text>
    """
    n = parse_node(xmlroot(str3), PnmlIDRegistry())
    @test n == "ready"

    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_node(xmlroot(str4), PnmlIDRegistry())
    @test n == "ready\nto\ngo"
end

@testset "labels" begin
    # Exersize the :labels of a PnmlDict

    d = PnmlDict(:labels => PnmlLabel[])
    reg = PnmlIDRegistry()
    @test_call labels(d)
    @test labels(d) isa Vector{PnmlLabel}
    for i in 1:4 # add 4 labels
        x = i < 3 ? 1 : 2 # make 2 tagnames
        node = xmlroot("<test$x> $i </test$x>")
        @test_call add_label!(d, node, PnmlCoreNet(), reg)
        n = add_label!(d, node, PnmlCoreNet(), reg)
        @test n isa Vector{PnmlLabel}
        #@show n
        @test length(labels(d)) == i
        @test d[:labels] == n
        @test labels(d) == n
    end

    @test length(d[:labels]) == 4
    @test length(labels(d)) == 4
    foreach(labels(d)) do l
        @test_call tag(l)
        @test tag(l) === :test1 || tag(l) === :test2
        @test xmlnode(l) isa Maybe{EzXML.Node}
        @test xmlnode(l) isa Maybe{XMLNode}
    end

    @test_call has_label(d, :test1)
    @test_call get_label(d, :test1)
    @test_call get_labels(d, :test1)

    @test has_label(d, :test1)
    @test !has_label(d, :bumble)

    v = get_label(d, :test2)
    @test v.dict[:content] == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        v = PNML.get_labels(d, labeltag)
        @test length(v) == 2
        for l in v
            @test tag(l) === labeltag
        end
    end
end

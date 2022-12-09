using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, xmlnode, xmlroot, labels,
        unclaimed_label, anyelement, PnmlLabel, AnyElement

@testset "unclaimed" begin
    # node => [key => value] expected to be in the PnmlDict after parsing node.
    ctrl = [
        xml"""<declarations> </declarations>""" =>
                [:content => ""],

        xml"""<declarations atag="test1"> </declarations>""" =>
                [:atag => "test1", :content => ""],

        xml"""<declarations atag="test2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="two"> <value/> <value tag3="three"/> </something2>
              </declarations>""" => [
                :atag => "test2",
                :something  => [Dict(:content => "some content"),
                                Dict(:content => "other stuff")],
                :something2 => Dict(:value => [Dict(:content => ""),
                                               Dict(:tag3 => "three", :content => "")],
                                    :tag2 => "two")
            ],

        xml"""<foo><declarations> </declarations></foo>""" =>
                [:declarations => Dict(:content => "")],

        # no content, no attribute results in empty dict.
        xml"""<null></null>""" => [],
        xml"""<null2/>""" => [],
        # no content, with attribute
        xml"""<null at="null"></null>""" =>
            [:at => "null"],
        xml"""<null2 at="null2" />""" =>
            [:at => "null2"],

        # empty content, no attribute
        xml"""<empty> </empty>""" =>
            [:content => ""],
        # empty content, with attribute
        xml"""<empty at="empty"> </empty>""" => [
            :content => "",
            :at => "empty"
            ],

        xml"""<foo id="testid"/>""" =>
            [:id => :testid],
        ]

    for (node,funk) in ctrl

        reg1 = IDRegistry()
        reg2 = IDRegistry()

        u = unclaimed_label(node, reg=reg1)
        l = PnmlLabel(u, node)
        a = anyelement(node, reg=reg2)

        #@show u
        #@show l
        #@show a

        @test_call unclaimed_label(node, reg=reg1)
        @test_call PnmlLabel(u, node)
        @test_call anyelement(node, reg=reg2)

        @test !isnothing(u)
        @test !isnothing(l)
        @test !isnothing(a)

        @test u isa Pair{Symbol, Dict{Symbol, Any}}
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
        for (key,val) in funk
            #@show typeof(key), typeof(val)#@show key#@show val
            @test haskey(u.second, key)
            @test u.second[key] == val
            @test haskey(l.dict,key)
            @test l.dict[key] == val
            @test haskey(a.dict,key)
            @test a.dict[key] == val
        end

        haskey(u.second, :id) && @test isregistered(reg1, u.second[:id])
        haskey(l.dict, :id) && @test isregistered(reg1, l.dict[:id])
        haskey(a.dict, :id) && @test isregistered(reg2, a.dict[:id])

        @test_call  isregistered(reg2, :id)
    end
end

@testset "PT initMarking" begin
    node = xml"""
    <initialMarking>
        <text>1.0</text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics>
                <tokenposition x="6" y="9"/>
            </tokengraphics>
        </toolspecific>
    </initialMarking>
    """

    n = parse_node(node; reg=IDRegistry())
    @test typeof(n) <: PNML.PTMarking
    #@test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(n.value) <: Union{Int,Float64}
    @test n.value == n()

    mark1 = PNML.PTMarking(2)
    @test_call PNML.PTMarking(2)
    @test typeof(mark1()) == typeof(2)
    @test mark1() == 2
    @test_call mark1()

    mark2 = PNML.PTMarking(3.5)
    @test_call PNML.PTMarking(3.5)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()

    mark3 = PNML.PTMarking()
    @test_call PNML.PTMarking()
    @test typeof(mark3()) == typeof(PNML.default_marking(PnmlCore())())
    @test mark3() == PNML.default_marking(PnmlCore())()
    @test_call mark3()
end

@testset "PT inscription" begin
    n1 = xml"<inscription> <text> 12 </text> </inscription>"
    @testset for node in [n1]
        n = parse_node(node; reg = PNML.IDRegistry())
        @test typeof(n) <: PNML.PTInscription
        #@test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.value == 12
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "text" begin
    str1 = """<text>ready</text>"""
    n = parse_node(xmlroot(str1); reg = PNML.IDRegistry())
    @test n == "ready"

    str2 = """
<text>
ready
</text>
    """
    n = parse_node(xmlroot(str2); reg = PNML.IDRegistry())
    @test n == "ready"

    str3 = """
 <text>    ready  </text>
    """
    n = parse_node(xmlroot(str3); reg = PNML.IDRegistry())
    @test n == "ready"

    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_node(xmlroot(str4); reg = PNML.IDRegistry())
    @test n == "ready\nto\ngo"
end

@testset "labels" begin
    # Exersize the :labels of a PnmlDict

    d = PNML.PnmlDict(:labels => PNML.PnmlLabel[])
    reg = PNML.IDRegistry()
    @test_call PNML.labels(d)
    @test PNML.labels(d) isa Vector{PNML.PnmlLabel}
    for i in 1:4 # add 4 labels
        x = i<3 ? 1 : 2 # make 2 tagnames
        node = xmlroot("<test$x> $i </test$x>")
        @test_call PNML.add_label!(d, node, PnmlCore(); reg)
        n = PNML.add_label!(d, node, PnmlCore(); reg)
        @test n isa Vector{PnmlLabel}
        #@show n
        @test length(PNML.labels(d)) == i
        @test d[:labels] == n
        @test PNML.labels(d) == n
    end

    @test length(d[:labels]) == 4
    @test length(labels(d)) == 4
    foreach(PNML.labels(d)) do l
        @test_call tag(l)
        @test tag(l) === :test1 || tag(l) === :test2
        @test xmlnode(l) isa Maybe{EzXML.Node}
    end

    @test_call PNML.has_label(d, :test1)
    @test_call PNML.get_label(d, :test1)
    @test_call PNML.get_labels(d, :test1)

    @test PNML.has_label(d, :test1)
    @test !PNML.has_label(d, :bumble)

    v = PNML.get_label(d, :test2)
    @test v.dict[:content] == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        v = PNML.get_labels(d, labeltag)
        @test length(v) == 2
        for l in v
            @test tag(l) === labeltag
        end
    end
end

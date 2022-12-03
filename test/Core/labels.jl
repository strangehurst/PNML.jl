using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, xmlnode, xmlroot, labels

#!header("PARSE CORE LABELS")

#!header("UNCLAIMED LABEL")
@testset "unclaimed" begin
    # node => vector of key, value pairs expected to be in the PnmlDict from parsing node.
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

        xml"""<foo><declarations> </declarations></foo>""" => [
            :declarations => Dict(:content => "")
            ],

        # no content, no attribute results in empty dict.
        xml"""<null></null>""" => [],
        xml"""<null2/>""" => [],
        # no content, with attribute
        xml"""<null at="null"></null>""" => [
            :at => "null"
            ],
        xml"""<null2 at="null2" />""" => [
            :at => "null2"
            ],

        # empty content, no attribute
        xml"""<empty> </empty>""" => [
            :content => ""
            ],
        # empty content, with attribute
        xml"""<empty at="empty"> </empty>""" => [
            :content => "",
            :at => "empty"
            ],

        xml"""<foo id="testid"/>""" => [
            :id => :testid
            ],
        ]

    for (node,funk) in ctrl

        reg1 = IDRegistry()
        reg2 = IDRegistry()

        u = PNML.unclaimed_label(node, reg=reg1)
        l = PNML.PnmlLabel(u, node)
        a = PNML.anyelement(node, reg=reg2)

        #@show u
        #@show l
        #@show a

        @test_call PNML.unclaimed_label(node, reg=reg1)
        @test_call PNML.PnmlLabel(u, node)
        @test_call PNML.anyelement(node, reg=reg2)

        @test !isnothing(u)
        @test !isnothing(l)
        @test !isnothing(a)

        @test u isa Pair{Symbol, Dict{Symbol, Any}}
        @test l isa PNML.PnmlLabel
        @test a isa PNML.AnyElement

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

        haskey(u.second, :id) && @test PNML.isregistered(reg1, u.second[:id])
        haskey(l.dict, :id) && @test PNML.isregistered(reg1, l.dict[:id])
        haskey(a.dict, :id) && @test PNML.isregistered(reg2, a.dict[:id])

        @test_call  PNML.isregistered(reg2, :id)

        #!println()
    end
end

#!header("PT initMarking")
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

    n = parse_node(node; reg=PNML.IDRegistry())
    #!printnode(n)
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
        #!printnode(n)
        @test typeof(n) <: PNML.PTInscription
        #@test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.value == 12
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "text" begin
    str1 = """
 <text>ready</text>
    """
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
    for i in 1:4
        x = i<3 ? 1 : 2
        node = xmlroot("<test$x> $i </test$x>")
        n = PNML.add_label!(d, node, PnmlCore(); reg)
        @test_call PNML.add_label!(d, node, PnmlCore(); reg)
        @test length(PNML.labels(d)) == i
        @test d[:labels] == n # Returned value is the vector
        @test PNML.labels(d) == n # Returned value is the vector
    end
    #!printnode(d)
    @test_call PNML.labels(d)
    # labels(d) infers as Any
    @test PNML.labels(d) isa Vector{PNML.PnmlLabel}
    @test length(d[:labels]) == 4
    @test length(labels(d)) == 4
    foreach(PNML.labels(d)) do l
        @test_call tag(l)
        @test tag(l) === :test1 || tag(l) === :test2
        @test xmlnode(l) isa Maybe{EzXML.Node}
    end
    #!@show typeof(d), collect(keys(d))
    #!@show typeof(labels(d))

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

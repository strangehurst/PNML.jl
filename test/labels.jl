using PNML, EzXML, ..TestUtils, JET
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

    #    d = PnmlDict(:labels => PnmlLabel[])
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
    @test v.dict[:content] == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        v = PNML.get_labels(tup, labeltag)
        @test length(v) == 2
        for l in v
            @test tag(l) === labeltag
        end
    end
end

@testset "unclaimed" begin
    println("## test unclaimed, PnmlLabel, anyelement")
    function test_unclaimed(xmlstring::String, funk::NamedTuple)#Vector{<:Pair})
        noisy && print("+++++++++++++++++++\n",
                       "XML: ", xmlstring, "\n",
                       "funk: ", funk, "\n",
                       "-------------------\n")

        node::XMLNode = xmlroot(xmlstring)
        reg1 = registry()
        reg2 = registry()

        u = unclaimed_label(node, PnmlCoreNet(), reg1)
        l = PnmlLabel(u, node)
        a = anyelement(node, reg2)
        #noisy && @show typeof(u) typeof(l) typeof(a)
        noisy && @show u l a

        # unclaimed_label returns Pair{Symbol,Vector{Pair{Symbol,Any}}}
        # Where the outer symbol is the label name and the vector is the label's contents.
        # function_filter(@nospecialize(ft)) = ft !== typeof(PnmlIDRegistrys.register_id!)

        @test_opt broken=true function_filter=pnml_function_filter target_modules=target_modules unclaimed_label(node, PnmlCoreNet(), reg1)
        @test_opt broken=false PnmlLabel(u, node)
        @test_opt broken=true function_filter=pnml_function_filter target_modules = (PNML,) anyelement(node, reg2)

        @test_call target_modules = (PNML,) unclaimed_label(node, PnmlCoreNet(), reg1) #!
        @test_call target_modules = (PNML,) PnmlLabel(u, node)
        @test_call target_modules = (PNML,) anyelement(node, reg2) #!

        @test !isnothing(u)
        @test !isnothing(l)
        @test !isnothing(a)


        @test u isa Pair{Symbol, <:NamedTuple}
        #@test u isa Pair{Symbol, Vector{Pair{Symbol,NamedTuple{Symbol}}}}
        @test l isa PnmlLabel
        @test a isa AnyElement

        @show nn = Symbol(nodename(node))
        @test u.first === nn
        @test tag(l) === nn
        @test tag(a) === nn

        @test u.second isa NamedTuple #!Vector{<:Pair}
        #@test u.second isa Vector{<:Pair{Symbol}}
        #@test u.second isa Vector{<:Pair{Symbol,Any}}
        #@test_broken u.second isa Vector{<:Pair{Symbol,<:NamedTuple}}
        @test l.dict isa NamedTuple
        @test a.dict isa NamedTuple

        @show typeof(funk)
        # test each key,value pair
        println("-------------------")
        for (key, val) in pairs(funk) # NamedTuple
            @show key #typeof(key)
            @show val #typeof(val) #eltype(val)
            #@show typeof(l.dict) eltype(l.dict) typeof(a.dict) eltype(a.dict)
            #@show vec = [v.first for v in u.second]
            #@test hasproperty(u.second, key)
            #@est any(==(key), vec)
            #inx = Base.findfirst(==(val), [v.first for v in u.second])
            #@test !isnothing(inx)
            #@test u.second[inx].first == val
            @test hasproperty(l.dict, key)
            #@show typeof(l.dict[key])
            #@test typeof(l.dict[key]) <: typeof(val)
            #@test l.dict[key] == val

            @test hasproperty(a.dict, key)
            #@show typeof(a.dict[key])
            #@test typeof(a.dict[key]) <: typeof(val)
            #@test a.dict[key] == val

            println()
        end
        println("^^^^^^^^^^^^^^^^^^^")

        #haskey(u.second, :id) && @test isregistered_id(reg1, u.second[:id])
        haskey(l.dict, :id) && @test isregistered_id(reg1, l.dict[:id])
        haskey(a.dict, :id) && @test isregistered_id(reg2, a.dict[:id])

        #@report_opt isregistered_id(reg2, :id)
        @test_call isregistered_id(reg2, :id)
    end

    ctrl = [
        ("""<declarations> </declarations>""", (; :content => "")),
        ("""<declarations atag="test1"> </declarations>""", (; :atag => "test1", :content => "")),
        ("""<declarations atag="test2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="two"> <value/> <value tag3="three"/> </something2>
            </declarations>""",
            (; :atag => "test2",
               :something => [(; :content => "some content"),
                              (; :content => "other stuff")],
               :something2 => [(; :tag2 => "two",
                                  :value => [(; :content => ""),
                                             (; :tag3 => "three", :content => "")],
                                )]),
                (tag2 = "two", value = NamedTuple[(content = "",), (tag3 = "three", content = "")])
        ),
        ("""<foo><declarations> </declarations></foo>""",
             (; :declarations => [(; :content => "")])),
            # no content, no attribute results in empty PnmlDict.
        ("""<null></null>""", NamedTuple()),
        ("""<null2/>""", NamedTuple()),
        # no content, with attribute
        ("""<null at="null"></null>""", (; :at => "null")),
        ("""<null2 at="null2" />""", (; :at => "null2")),
        # empty content, no attribute
        ("""<empty> </empty>""", (; :content => "")),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""", (; :content => "", :at => "empty")),
        ("""<foo id="testid"/>""", (; :id => :testid)),
    ]

    for (s, funk) in ctrl
        test_unclaimed(s, funk)
    end
end

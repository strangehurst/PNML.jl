header("PARSE_LABELS")

header("UNCLAIMED LABEL")
@testset "unclaimed" begin
    # The funk are key, value pairs expected to be in the PnmlDict.
    for (node,funk) in [
        xml"""<declarations> </declarations>""" => [
            :content => ""
            ],
        xml"""<declarations atag="test1"> </declarations>""" => [
            :atag => "test1",
            :content => ""
            ],

            xml"""<declarations atag="test2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="two"> <value/> <value tag3="three"/> </something2>
              </declarations>""" => [
            :atag => "test2",
            :something  => [Dict(:content => "some content"), Dict(:content => "other stuff")],
            :something2 => Dict(:value => [Dict(), Dict(:tag3 => "three")], :tag2 => "two")
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
        reg1=PNML.IDRegistry()
        reg2=PNML.IDRegistry()
        u = PNML.unclaimed_label(node, reg=reg1)
        l = PNML.PnmlLabel(u, node)
        a = PNML.anyelement(node, reg=reg2)

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

        for (key,val) in funk
            @test u.second[key] == val
            @test l.dict[key] == val
            @test a.dict[key] == val
        end
        
        haskey(u.second, :id) && @test PNML.isregistered(reg1, u.second[:id])
        haskey(l.dict, :id) && @test PNML.isregistered(reg1, l.dict[:id])
        haskey(a.dict, :id) && @test PNML.isregistered(reg2, a.dict[:id])

        @show u
        @show l
        @show a
        println()
    end
end

header("GET_LABEL")
@testset "get rate label" begin
    n = parse_node(xml"""<transition id ="birth">
        <rate> <text>0.3</text> </rate>
    </transition>""", reg=PNML.IDRegistry())
    printnode(n)
    l = PNML.labels(n)
    @test PNML.tag(first(l)) === :rate # only label
    @test PNML.get_label(n, :rate) === first(PNML.labels(n))
    @test PNML.rate(n) ≈ 0.3
end

header("DECLARATION")
@testset "empty declarations" begin
    # The attribute should be ignored.
    n = parse_node(xml"""
        <declaration key="test">
          <structure>
           <declarations>
           </declarations>
          </structure>
        </declaration>
        """; reg= PNML.IDRegistry())

    @show typeof(n), fieldnames(typeof(n))
    printnode(n)

    @test typeof(n) <: PNML.Declaration
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(PNML.declarations(n)) <: Vector{PNML.AbstractDeclaration}
    @test length(PNML.declarations(n)) == 0
    @test typeof(n.com) <: PNML.ObjectCommon
    #@test PNML.name(n) === nothing
    @test PNML.graphics(n) === nothing
    @test PNML.tools(n) === nothing
    @test PNML.labels(n) === nothing
    @test isempty(n.com)
end

@testset "declaration tree" begin
        node = xml"""
        <declaration>
            <structure>
                <declarations>
                    <namedsort id="LegalResident" name="LegalResident">
                        <cyclicenumeration>
                            <feconstant id="LegalResident0" name="0"/>
                            <feconstant id="LegalResident1" name="1"/>
                        </cyclicenumeration>
                    </namedsort>
                    <namedsort id="MICSystem" name="MICSystem">
                        <cyclicenumeration>
                            <feconstant id="MICSystem0" name="0"/>
                            <feconstant id="MICSystem1" name="1"/>
                        </cyclicenumeration>
                    </namedsort>
                    <namedsort id="CINFORMI" name="CINFORMI">
                        <cyclicenumeration>
                            <feconstant id="CINFORMI0" name="0"/>
                            <feconstant id="CINFORMI1" name="1"/>
                        </cyclicenumeration>
                    </namedsort>
            </declarations>
        </structure>
    </declaration>
    """
    reg = PNML.IDRegistry()
    n = parse_node(node; reg)
    printnode(n)

    @test typeof(n) <: PNML.Declaration
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test length(PNML.declarations(n)) == 3
    for d in PNML.declarations(n)
        @test typeof(d) <: PNML.AbstractDeclaration
        @test typeof(d) <: PNML.SortDeclaration
        @test typeof(d) <: PNML.NamedSort

        #@show d
        #@show fieldtypes(typeof(d))
        #@show fieldnames(typeof(d))
        #@show fieldtypes(typeof(d.def))
        #@show fieldnames(typeof(d.def))

        @test PNML.isregistered(reg, pid(d))
        @test Symbol(PNML.name(d)) === pid(d) # name and id are the same.
        @test d.def isa PNML.AnyElement #TODO implement definitions?
        @test tag(d.def) === :cyclicenumeration
        @test haskey(d.def.dict, :feconstant)

        for x in d.def.dict[:feconstant]
            @test x isa PnmlDict
            @test PNML.isregistered(reg, pid(x))
            @test x[:name] isa String
            @test endswith(string(pid(x)), x[:name])
        end
        #println()
    end
end

header("PT initMarking")
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
    printnode(n)
    @test typeof(n) <: PNML.PTMarking
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(n.value) <: Number
    @test n.value == n()

    mark1 = PNML.PTMarking(2)
    @test typeof(mark1()) == typeof(2)
    @test mark1() == 2
    mark2 = PNML.PTMarking(3.5)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    mark3 = PNML.PTMarking()
    @test typeof(mark3()) == typeof(PNML.default_marking(PnmlCore()))
    @test mark3() == PNML.default_marking(PnmlCore())
end

header("HL Marking")
@testset "HL initMarking" begin
    str = """
 <hlinitialMarking>
     <text>&lt;All,All&gt;</text>
     <structure>
            <tuple>
              <subterm>
                <all>
                  <usersort declaration="N1"/>
                </all>
              </subterm>
              <subterm>
                <all>
                  <usersort declaration="N2"/>
                </all>
              </subterm>
            </tuple>
     </structure>
 </hlinitialMarking>
    """
    n = parse_node(to_node(str); reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.AbstractLabel
    @test typeof(n) <: PNML.HLMarking
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test n.text == "<All,All>"
    @test n.term !== nothing
    @test n.term isa PNML.AbstractTerm
    @show typeof(n.term)
    @show n.term
    #@test n.structure.dict[:tuple].dict[:subterm][1].dict[:all] !== nothing
    #@test n.structure.dict[:tuple].dict[:subterm][1].dict[:all].dict[:usersort].dict[:declaration] == "N1"
    #@test n.structure.dict[:tuple].dict[:subterm][2].dict[:all].dict[:usersort].dict[:declaration] == "N2"
end

@testset "text" begin
    str1 = """
 <text>ready</text>
    """
    n = parse_node(to_node(str1); reg = PNML.IDRegistry())
    @test n == "ready"

    str2 = """
 <text>
ready
</text>
    """
    n = parse_node(to_node(str2); reg = PNML.IDRegistry())
    @test n == "ready"

    str3 = """
 <text>    ready  </text>
    """
    n = parse_node(to_node(str3); reg = PNML.IDRegistry())
    @test n == "ready"

    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_node(to_node(str4); reg = PNML.IDRegistry())
    @test n == "ready\nto\ngo"
end

header("STRUCTURE")
@testset "structure" begin
    node = xml"""
     <structure>
         <tuple>
              <subterm>
                <all>
                  <usersort declaration="N1"/>
                </all>
              </subterm>
              <subterm>
                <all>
                  <usersort declaration="N2"/>
                </all>
              </subterm>
         </tuple>
     </structure>
    """

    n = parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test n isa PNML.Structure
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test tag(n) === :structure
    @test n.dict isa PnmlDict
    @test n.dict[:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n.dict[:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

header("SORT TYPE")
@testset "type" begin
    n1 = xml"""
 <type>
     <text>N2</text>
     <structure> <usersort declaration="N2"/> </structure>
 </type>
    """
    @testset for node in [n1]
        n = parse_node(node; reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.AnyElement
        @test tag(n) === :type
        @test n.dict[:text][:content] == "N2"
        @test n.dict[:structure][:usersort][:declaration] == "N2"
    end
end

header("CONDITION")
@testset "condition" begin
    n1 = xml"""
 <condition>
     <text>(x==1 and y==1 and d==1)</text>
     <structure> <or> #TODO </or> </structure>
 </condition>
    """
    @testset for node in [n1]
        n = parse_node(node; reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.Condition
        @test n.text !== nothing
        @test n.term !== nothing
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "inscription" begin
    n1 = xml"""
        <inscription> <text>12 </text> </inscription>
    """
    @testset for node in [n1]
        n = parse_node(node; reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.PTInscription
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.value == 12
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "hlinscription" begin
    n1 = xml"""
 <hlinscription>
     <text>&lt;x,v&gt;</text>
     <structure>
            <tuple>
              <subterm>
                <variable refvariable="x"/>
              </subterm>
              <subterm>
                <variable refvariable="v"/>
              </subterm>
            </tuple>
     </structure>
 </hlinscription>
 """
    @testset for node in [n1]
        n = parse_node(node; reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.HLInscription
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.term !== nothing
        @test n.text !== nothing
    end
end

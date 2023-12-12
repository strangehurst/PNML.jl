using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, value, text, elements, all_nettypes, ishighlevel, DictType

@testset "HL initMarking $pntd" for pntd in all_nettypes(ishighlevel)
    str = """
 <hlinitialMarking>
    <text>&lt;All,All&gt;</text>
    <structure>
        <tuple>
            <subterm><all><usersort declaration="N1"/></all></subterm>
            <subterm><all><usersort declaration="N2"/></all></subterm>
        </tuple>
    </structure>
    <graphics><offset x="0" y="0"/></graphics>
    <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    <unknown id="unkn">
        <name> <text>unknown label</text> </name>
        <text>content text</text>
    </unknown>
 </hlinitialMarking>
    """
    println()
    mark = (@test_logs (:warn,"ignoring unexpected child of <hlinitialMarking>: unknown") PNML.parse_hlinitialMarking(xmlroot(str), pntd, registry()))

    @test mark isa PNML.AbstractLabel
    @test mark isa PNML.marking_type(pntd) #HLMarking

    # Following HL text,structure label pattern where structure is a `Term`.
    @test text(mark) == "<All,All>"
    @test value(mark) isa PNML.AbstractTerm
    @test value(mark) isa PNML.Term
    print("mark = "); pprintln(mark) # show

    @test PNML.has_graphics(mark) == true
    @test PNML.has_labels(mark) == false
    @show mark #! debug
    markterm = value(mark)
    @test tag(markterm) === :tuple # pnml many-sorted algebra's tuple

    axn = elements(markterm)
    #TODO HL implementation not complete:
    #TODO  evaluate the HL expression, check place sorttype

    #@show axn #! debug
    pprintln(axn)
#     axn = OrderedDict{Union{String, Symbol}, Any}("subterm" =>
#         Any[OrderedDict{Union{String, Symbol}, Any}("all" => OrderedDict{Union{String, Symbol}, Any}("usersort" => OrderedDict{Union{String, Symbol}, Any}(:declaration => "N1"))),
#             OrderedDict{Union{String, Symbol}, Any}("all" => OrderedDict{Union{String, Symbol}, Any}("usersort" => OrderedDict{Union{String, Symbol}, Any}(:declaration => "N2")))
#             ])

    # Decend each element of the term.
    @test tag(axn) == "subterm"
    @test value(axn) isa Vector #!{DictType}

    all1 = value(axn)[1]
    @test tag(all1) == "all"
    @test value(all1) isa DictType
    use1 = value(all1)["usersort"]
    @test use1 isa DictType
    @test use1[:declaration] == "N1"
    @test PNML._attribute(use1, :declaration) == "N1"

    all2 = value(axn)[2]
    @test tag(all2) == "all"
    @test value(all2) isa DictType
    use2 = value(all2)["usersort"]
    @test use2 isa DictType
    @test use2[:declaration] == "N2"
    @test PNML._attribute(use2, :declaration) == "N2"
end

@testset "hlinscription $pntd" for pntd in all_nettypes(ishighlevel)
    n1 = xml"""
    <hlinscription>
        <text>&lt;x,v&gt;</text>
        <structure>
            <tuple>
              <subterm><variable refvariable="x"/></subterm>
              <subterm><variable refvariable="v"/></subterm>
            </tuple>
        </structure>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
      </hlinscription>
    """
    insc = @test_logs (:warn,"ignoring unexpected child of <hlinscription>: unknown") PNML.parse_hlinscription(n1, pntd, registry())
    pprint("insc = "); pprintln(insc);
    @test typeof(insc) <: PNML.AbstractLabel
    @test typeof(insc) <: PNML.inscription_type(pntd)
    @test text(insc) isa Union{Nothing,AbstractString}
    @test text(insc) == "<x,v>"
    @test value(insc) isa PNML.AbstractTerm
    @test value(insc) isa PNML.Term
    @test PNML.has_graphics(insc) == true
    @test PNML.has_labels(insc) == false

    inscterm = value(insc)
    @test tag(inscterm) === :tuple
    axn = elements(inscterm)

    #TODO HL implementation not complete:

    sub1 = axn["subterm"][1]
    pprintln(sub1)
    @test tag(sub1) == "variable"
    var1 = PNML._attribute(sub1["variable"], :refvariable)
    @test var1 == "x"

    sub2 = axn["subterm"][2]
    pprintln(sub2)
    @test tag(sub2) == "variable"
    var2 = PNML._attribute(sub2["variable"], :refvariable)
    @test var2 == "v"
end

@testset "structure $pntd" for pntd in all_nettypes(ishighlevel)
    node = xml"""
     <structure>
        <tuple>
            <subterm><all><usersort declaration="N1"/></all></subterm>
            <subterm><all><usersort declaration="N2"/></all></subterm>
        </tuple>
     </structure>
    """

    stru = PNML.parse_structure(node, pntd, registry())
    @test stru isa PNML.Structure
    @show stru
    @test tag(stru) == :structure
    @test elements(stru) isa DictType
    axn = elements(stru)

    # expected structure: tuple -> subterm -> all -> usersort -> declaration

    tup = axn["tuple"]
    sub = tup["subterm"]
    @test sub isa Vector
    #--------
    all1 = sub[1]["all"]
    usr1 = all1["usersort"]
    @test value(usr1) == "N1"

    #--------
    all2 = sub[2]["all"]
    usr2 = all2["usersort"]
    @test value(usr2) == "N2"
end

@testset "type $pntd" for pntd in all_nettypes(ishighlevel)
    n1 = xml"""
<type>
    <text>N2</text>
    <structure> <usersort declaration="N2"/> </structure>
    <graphics><offset x="0" y="0"/></graphics>
    <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    <unknown id="unkn">
        <name> <text>unknown label</text> </name>
        <text>content text</text>
    </unknown>
</type>
    """
    @testset for node in [n1]
        typ =  @test_logs (:warn,"ignoring unexpected child of <type>: unknown") PNML.parse_type(node, pntd, registry())
        @test typ isa PNML.SortType
        #Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show typ
        #end
        @test text(typ) == "N2"
        @test value(typ) isa PNML.AbstractSort
        @test value(typ).declaration == :N2
        @test PNML.has_graphics(typ) == true
        @test PNML.has_labels(typ) == false
        end
end

# conditions are for everybody.
@testset "condition $pntd" for pntd in all_nettypes()
    n1 = xml"""
 <condition>
    <text>(x==1 and y==1 and d==1)</text>
    <structure> <or> #TODO </or> </structure>
    <graphics><offset x="0" y="0"/></graphics>
    <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    <unknown id="unkn">
        <name> <text>unknown label</text> </name>
        <text>content text</text>
    </unknown>
 </condition>
    """
    @testset for node in [n1]
        cond =  @test_logs (:warn,"ignoring unexpected child of <condition>: unknown") PNML.parse_condition(node, pntd, registry())
        @test cond isa PNML.condition_type(pntd)
        #Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show cond
        #end
        @test text(cond) == "(x==1 and y==1 and d==1)"
        @test value(cond) isa Union{PNML.condition_value_type(pntd), PNML.Term}
        @test tag(value(cond)) == :or
        @test PNML.has_graphics(cond) == true
        @test PNML.has_labels(cond) == false
    end
end

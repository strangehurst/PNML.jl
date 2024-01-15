using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, value, text, elements, all_nettypes, ishighlevel,
    DictType, XDVT

@testset "HL initMarking $pntd" for pntd in all_nettypes(ishighlevel)

    @testset "3`dot" begin
        node = xml"""
        <hlinitialMarking>
            <text>3`dot</text>
            <structure>
                <numberof>
                    <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                    <subterm><dotconstant/></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        # numberof is an operator: natural number, element of a sort -> multiset
        # subterms are in an ordered collection, first is a number, second an element of a sort
        # Use the first part of this pair in contextes that want numbers.
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        @test mark isa PNML.marking_type(pntd)
        #pprint(mark)

        @test value(mark) isa PNML.AbstractTerm # Should be Variable or Operator
        @test text(mark) == "3`dot"

        @test PNML.has_graphics(mark) == false # This instance does not have any graphics.
        @test PNML.has_labels(mark) == false # Labels do not themselves have `Labels`, but you may ask.
        # Any `Label` children must be "well behaved xml".

        @show value(mark)

        markterm = value(mark)
        @test tag(markterm) === :numberof # pnml many-sorted operator -> multiset
        parameters = elements(markterm)["subterm"]
        @test length(parameters) == 2
        @test parameters[1]["numberconstant"][:value] == "3"
        @test isempty(parameters[2]["dotconstant"])

        #TODO HL implementation not complete:
        #TODO  evaluate the HL expression, check place sorttype

        #@show axn #! debug
    end

    @testset "<All,All>" begin #! Does this Term make sense as a marking?
        node = xml"""
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
        mark = @test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <hlinitialMarking>: 'unknown'"),
            PNML.parse_hlinitialMarking(node, pntd, registry()))

        @test mark isa PNML.AbstractLabel
        @test mark isa PNML.marking_type(pntd) #HLMarking
        #pprint(mark)

        # Following HL text,structure label pattern where structure is a `Term`.
        @test text(mark) == "<All,All>"
        @test value(mark) isa PNML.AbstractTerm
        @test value(mark) isa PNML.Term

        @test PNML.has_graphics(mark) == true
        @test PNML.has_labels(mark) == false

        @show value(mark)
        markterm = value(mark)
        @test tag(markterm) === :tuple # pnml many-sorted algebra's tuple

        axn = elements(markterm)

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

    @testset "useroperator" begin
        node = xml"""
        <hlinitialMarking>
            <text>useroperator</text>
            <structure>
                <useroperator declaration="id4"/>
            </structure>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show value(mark)
        #pprint(mark)
    end

    @testset "1`3 ++ 1`2" begin
        node = xml"""
        <hlinitialMarking>
            <text>1`3 ++ 1`2</text>
            <structure>
                <add>
                    <subterm>
                        <numberof>
                        <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                        <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                    <subterm>
                        <numberof>
                        <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                        <subterm><numberconstant value="2"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                </add>
            </structure>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show mark
        @show value(mark)
        #pprint(mark)
    end

    @testset "1`8" begin
        node = xml"""
        <hlinitialMarking>
            <text>1`8</text>
            <structure>
                <numberof>
                <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                <subterm><numberconstant value="8"><positive/></numberconstant></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show mark
        @show value(mark)
        #pprint(mark)
    end

    @testset "x" begin
        node = xml"""
        <hlinitialMarking>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show mark
        @show value(mark)
        #pprint(mark)
    end

    println()
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
    insc = @test_logs(match_mode=:all, (:warn,"ignoring unexpected child of <hlinscription>: 'unknown'"),
            #(:info, "parse_term kinds are Variable and Operator"),
            PNML.parse_hlinscription(n1, pntd, registry()))

    @test typeof(insc) <: PNML.AbstractLabel
    @test typeof(insc) <: PNML.inscription_type(pntd)
    @test PNML.has_graphics(insc) == true
    @test PNML.has_labels(insc) == false

    @test text(insc) isa Union{Nothing,AbstractString}
    @test text(insc) == "<x,v>"

    #@show value(insc)
    inscterm = value(insc)
    @test inscterm isa PNML.Term
    @test tag(inscterm) === :tuple
    axn = elements(inscterm)

    #TODO HL implementation not complete:

    sub1 = axn["subterm"][1]
    @test tag(sub1) == "variable"
    var1 = PNML._attribute(sub1["variable"], :refvariable)
    @test var1 == "x"

    sub2 = axn["subterm"][2]
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
    # expected structure: tuple -> subterm -> all -> usersort -> declaration

    stru = PNML.parse_structure(node, pntd, registry())
    @test stru isa PNML.Structure
    @test tag(stru) == :structure
    axn = elements(stru)
    @test axn isa DictType

    tup = axn["tuple"]
    sub = tup["subterm"]
    #--------
    all1 = sub[1]["all"]
    usr1 = all1["usersort"]
    @test value(usr1) == "N1"
    @test value(axn["tuple"]["subterm"][1]["all"]["usersort"]) == "N1"
    #--------
    all2 = sub[2]["all"]
    usr2 = all2["usersort"]
    @test value(usr2) == "N2"
    @test value(axn["tuple"]["subterm"][2]["all"]["usersort"]) == "N2"
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
        typ =  @test_logs (:warn,"ignoring unexpected child of <type>: 'unknown'") PNML.parse_type(node, pntd, registry())
        @test typ isa PNML.SortType
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
        cond = @test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <condition>: 'unknown'"),
                #(:info, "parse_term kinds are Variable and Operator"),
                PNML.parse_condition(node, pntd, registry()))
        @test cond isa PNML.condition_type(pntd)
        @test text(cond) == "(x==1 and y==1 and d==1)"
        @test value(cond) isa Union{PNML.condition_value_type(pntd), PNML.Term}
        @test tag(value(cond)) == :or
        @test PNML.has_graphics(cond) == true
        @test PNML.has_labels(cond) == false
    end
end

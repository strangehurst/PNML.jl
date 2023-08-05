using PNML, EzXML, ..TestUtils, JET, PrettyPrinting
using PNML: Maybe, tag, pid, xmlnode, value, text, elements, AnyXmlNode

@testset "HL initMarking $pntd" for pntd in Iterators.filter(PNML.ishighlevel, values(PNML.PnmlTypeDefs.pnmltype_map))
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
    mark = PNML.parse_hlinitialMarking(xmlroot(str), pntd, registry())

    @test mark isa PNML.AbstractLabel
    @test mark isa PNML.marking_type(HLCoreNet()) #HLMarking

    # Following HL text,structure label pattern where structure is a `Term`.
    @test text(mark) == "<All,All>"
    @test value(mark) isa PNML.AbstractTerm
    @test value(mark) isa PNML.Term
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show mark
    end

    markterm = value(mark)
    @test tag(markterm) === :tuple # pnml many-sorted algebra's tuple
    axn = elements(markterm)

    # Decend each element of the term.
    sub1 = axn[1]
    @test tag(sub1) === :subterm
    @test value(sub1) isa Vector{AnyXmlNode}

    all1 = value(sub1)[1]
    @test tag(all1) === :all
    @test value(all1) isa Vector{AnyXmlNode}

    use1 = value(all1)[1]
    @test tag(use1) === :usersort
    @test value(use1) isa Vector{AnyXmlNode}

    @test tag(value(use1)[1]) === :declaration
    @test value(value(use1)[1]) == "N1"

    #println("\n## axn[2]"); dump(axn[2])
    sub2 = axn[2]
    @test tag(sub2) === :subterm
    @test value(sub2) isa Vector{AnyXmlNode}

    all2 = value(sub2)[1]
    @test tag(all2) === :all
    @test value(all2) isa Vector{AnyXmlNode}

    use2 = value(all2)[1]
    @test tag(use2) === :usersort
    @test value(use2) isa Vector{AnyXmlNode}

    @test tag(value(use2)[1]) === :declaration
    @test value(value(use2)[1]) == "N2"
end

@testset "hlinscription $pntd" for pntd in Iterators.filter(PNML.ishighlevel, values(PNML.PnmlTypeDefs.pnmltype_map))
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
    insc = PNML.parse_hlinscription(n1, pntd, registry())
    @test typeof(insc) <: PNML.AbstractLabel
    @test typeof(insc) <: PNML.inscription_type(pntd)
    @test text(insc) isa Union{Nothing,AbstractString}
    @test text(insc) == "<x,v>"
    @test value(insc) isa PNML.AbstractTerm
    @test value(insc) isa PNML.Term
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show insc
    end

    inscterm = value(insc)
    @test tag(inscterm) === :tuple
    axn = elements(inscterm)

    sub1 = axn[1]
    @test tag(sub1) === :subterm
    @test value(sub1) isa Vector{AnyXmlNode}

    var1 = value(sub1)[1]
    @test tag(var1) === :variable
    @test value(var1) isa Vector{AnyXmlNode}

    ref1 = value(var1)[1]
    @test tag(ref1) === :refvariable
    @test value(ref1) == "x"

    sub2 = axn[2]
    @test tag(sub2) === :subterm
    @test value(sub2) isa Vector{AnyXmlNode}

    var2 = value(sub2)[1]
    @test tag(var2) === :variable
    @test value(var2) isa Vector{AnyXmlNode}

    ref2 = value(var2)[1]
    @test tag(ref2) === :refvariable
    @test value(ref2) == "v"
end

@testset "structure $pntd" for pntd in Iterators.filter(PNML.ishighlevel, values(PNML.PnmlTypeDefs.pnmltype_map))
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
    @test xmlnode(stru) isa Maybe{EzXML.Node}

    #println("\n## stru = "); dump(stru)
    @test tag(stru) === :structure
    @test elements(stru) isa Vector{AnyXmlNode}
    @test tag(stru) === :structure
    axn = elements(stru)

    # expected structure: tuple -> subterm -> all -> usersort -> declaration

    tup1 = axn[1]
    @test tag(tup1) === :tuple
    @test value(tup1) isa Vector{AnyXmlNode}

    #--------
    sub1 = value(tup1)[1]
    @test tag(sub1) === :subterm
    @test value(sub1) isa Vector{AnyXmlNode}

    all1 = value(sub1)[1]
    @test tag(all1) === :all
    @test value(all1) isa Vector{AnyXmlNode}

    usr1 = value(all1)[1]
    @test tag(usr1) === :usersort
    @test value(usr1) isa Vector{AnyXmlNode}

    dec1 = value(usr1)[1]
    @test tag(dec1) === :declaration
    @test value(dec1) == "N1"

    #--------
    sub2 = value(tup1)[2]
    @test tag(sub2) === :subterm
    @test value(sub2) isa Vector{AnyXmlNode}

    all2 = value(sub2)[1]
    @test tag(all2) === :all
    @test value(all2) isa Vector{AnyXmlNode}

    usr2 = value(all2)[1]
    @test tag(usr2) === :usersort
    @test value(usr2) isa Vector{AnyXmlNode}

    dec2 = value(usr2)[1]
    @test tag(dec2) === :declaration
    @test value(dec2) == "N2"
end

@testset "type $pntd" for pntd in Iterators.filter(PNML.ishighlevel, values(PNML.PnmlTypeDefs.pnmltype_map))
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
        typ = PNML.parse_type(node, pntd, registry())
        @test typ isa PNML.SortType
        #println("\n## SortType typ "); dump(typ)
        @test text(typ) == "N2"
        @test value(typ) isa PNML.AbstractSort
        @test value(typ).declaration == :N2
    end
end

# conditions are for everybody.
@testset "condition $pntd" for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
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
        cond = PNML.parse_condition(node, pntd, registry())
        #println("parse_condition"); dump(cond)
        @test cond isa PNML.condition_type(pntd)
        Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show cond
        end
        @test text(cond) == "(x==1 and y==1 and d==1)"
        @test value(cond) isa Union{PNML.condition_value_type(pntd),
                                    PNML.Term #!{PNML.condition_value_type(pntd)}
                                    }

        @test tag(value(cond)) === :or
        @test PNML.has_graphics(cond)
        @test PNML.has_tools(cond)
        @test PNML.has_labels(cond)
    end
end

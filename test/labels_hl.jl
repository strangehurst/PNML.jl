using PNML, EzXML, ..TestUtils, JET, PrettyPrinting
using PNML: Maybe, tag, pid, xmlnode, value, text, elements, AnyXmlNode

@testset "HL initMarking" begin
    str = """
 <hlinitialMarking>
     <text>&lt;All,All&gt;</text>
     <structure>
            <tuple>
              <subterm><all><usersort declaration="N1"/></all></subterm>
              <subterm><all><usersort declaration="N2"/></all></subterm>
            </tuple>
     </structure>
 </hlinitialMarking>
    """
    mark = PNML.parse_hlinitialMarking(xmlroot(str), HLCoreNet(), registry())

    @test typeof(mark) <: PNML.AbstractLabel
    @test typeof(mark) <: PNML.HLMarking
    @test text(mark) == "<All,All>"
    @test value(mark) isa PNML.AbstractTerm
    @test value(mark) isa PNML.Term

    markterm = value(mark)
    #println("\n## mark term $(tag(markterm))"); dump(markterm)

    @test tag(markterm) === :tuple #! pnml many-sorted algebra tuple
    axn = elements(markterm)

    # expected structure: subterm -> all -> usersort

    #println("\n## axn[1]"); dump(axn[1])
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

@testset "hlinscription" begin
    n1 = xml"""
    <hlinscription>
        <text>&lt;x,v&gt;</text>
        <structure>
            <tuple>
              <subterm><variable refvariable="x"/></subterm>
              <subterm><variable refvariable="v"/></subterm>
            </tuple>
        </structure>
    </hlinscription>
    """
    insc = PNML.parse_hlinscription(n1, HLCoreNet(), registry())
    @test typeof(insc) <: PNML.AbstractLabel
    @test typeof(insc) <: PNML.HLInscription
    @test text(insc) isa Union{Nothing,AbstractString}
    @test text(insc) == "<x,v>"
    @test value(insc) isa PNML.AbstractTerm
    @test value(insc) isa PNML.Term

    inscterm = value(insc)
    #println("\n## unsc term $(tag(inscterm))"); dump(inscterm)

    #@show insc value(insc)
    @test tag(inscterm) === :tuple
    axn = elements(inscterm)

    # expected structure: subterm -> variable

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

@testset "structure" begin
    node = xml"""
     <structure>
         <tuple>
            <subterm><all><usersort declaration="N1"/></all></subterm>
            <subterm><all><usersort declaration="N2"/></all></subterm>
         </tuple>
     </structure>
    """

    stru = PNML.parse_structure(node, HLCoreNet(), registry())
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

@testset "type" begin
    n1 = xml"""
 <type>
     <text>N2</text>
     <structure> <usersort declaration="N2"/> </structure>
 </type>
    """
    @testset for node in [n1]
        typ = PNML.parse_type(node, HLCoreNet(), registry())
        #print("SortType = "); pprintln(typ)
        @test typ isa PNML.SortType
        #println("\n## typ "); dump(typ)
        @test text(typ) == "N2"
        @test value(typ) isa PNML.Term
        @test (tag ∘ value)(typ) === :usersort
        @test (elements ∘ value)(typ) isa Vector{AnyXmlNode}

        axn = (elements ∘ value)(typ)[1]
        @test tag(axn) === :declaration
        @test value(axn) == "N2"
    end
end

@testset "condition" begin
    n1 = xml"""
 <condition>
     <text>(x==1 and y==1 and d==1)</text>
     <structure> <or> #TODO </or> </structure>
 </condition>
    """
    @testset for node in [n1]
        cond = PNML.parse_condition(node, PnmlCoreNet(), registry())
        #@show cond
        @test typeof(cond) <: PNML.Condition
        @test text(cond) !== nothing
        @test value(cond) !== nothing
        @test tag(value(cond)) === :or
        @test !PNML.has_graphics(cond)
        @test !PNML.has_tools(cond)
        @test !PNML.has_labels(cond)
    end
end

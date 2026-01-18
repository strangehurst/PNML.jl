using PNML, JET
using InteractiveUtils
using Printf

include("TestUtils.jl")
using .TestUtils

#!
#! TODO add tests for variable declarations
#!

@testset "empty declarations $pntd" for pntd in PnmlTypes.core_nettypes()
    ctx = PNML.Parser.parser_context()::PNML.ParseContext

        decl = parse_declaration!(ctx, xml"""<declaration key="test empty">
                <structure><declarations></declarations></structure>
            </declaration>""", pntd)::Declaration

        @test length(decl) == 7 # nothing in <declarations>
        @test !isempty(decl)
        @test PNML.graphics(decl) === nothing
        @test PNML.toolinfos(decl) === nothing

        @test occursin(r"^Declaration", sprint(show, decl))
        @test_opt PNML.decldict(decl)
        @test_opt PNML.graphics(decl)
        @test_opt PNML.toolinfos(decl)

        @test_call PNML.decldict(decl)
        @test_call PNML.graphics(decl)
        @test_call PNML.toolinfos(decl)
end

@testset "namedsort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
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
                <!-- namedoperator -->
                <!-- arbitrarysort, arbitraryoperator -->
            </declarations>
        </structure>
        <graphics>	<position x="11" y="22" /> </graphics>
        <toolspecific tool="sometool" version="6.6">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknownchild />
    </declaration>
    """

    ctx = PNML.Parser.parser_context()::PNML.ParseContext

        base_decl_length = length(PNML.namedsorts(ctx.ddict))
        decl = @test_logs(match_mode=:any, (:warn, r"^ignoring unexpected child"),
            parse_declaration!(ctx, node, pntd)::PNML.Declaration) # Add 3 declarations.
        @test length(PNML.namedsorts(ctx.ddict)) == base_decl_length + 3

        for nsort in values(PNML.namedsorts(ctx.ddict))
            #!@test typeof(nsort) <: PNML.NamedSort # is a declaration
            #@show nsort pid(nsort)
            @test isregistered(ctx.idregistry, pid(nsort))
            #!@test Symbol(PNML.name(nsort)) === pid(nsort) # NOT TRUE! name and id are the same.
            #!@test PNML.sortof(nsort) isa PNML.CyclicEnumerationSort
            #@test PNML.elements(PNML.sortof(nsort)) isa Vector{PNML.FEConstant}

            sortname = PNML.name(nsort)
            cesort   = PNML.sortdefinition(nsort)
            feconsts = PNML.sortelements(cesort) # should be iteratable ordered collection
            feconsts isa Vector{PNML.FEConstant}
            #!@test length(feconsts) == 2
            # for fec in feconsts
            #     @test fec isa PNML.FEConstant
            #     @test fec.id isa Symbol
            #     @test fec.name isa AbstractString
            #     @test isregistered(fec.id)
            #     @test endswith(string(fec.id), fec.name)
            # end
        end
end


@testset "partition declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="pluck" name="PLUCK">
                    <finiteenumeration>
                        <feconstant id="b1" name="b1" />
                        <feconstant id="b2" name="b2" />
                        <feconstant id="b3" name="b3" />
                   </finiteenumeration>
                </namedsort>
                <namedsort id="pluck2" name="PLUCK2">
                    <finiteenumeration>
                        <feconstant id="b4" name="b4" />
                        <feconstant id="b5" name="b5" />
                        <feconstant id="b6" name="b6" />
                   </finiteenumeration>
                </namedsort>

                <partition id="P1" name="P1">
                    <usersort declaration="pluck"/>
                    <partitionelement id="pe1" name="pe1">
                        <useroperator declaration="b1"/>
                        <useroperator declaration="b2"/>
                        <useroperator declaration="b3"/>
                    </partitionelement>tokenposition
                </partition>
                <partition id="P2" name="P2">
                    <usersort declaration="pluck2"/>
                    <partitionelement id="pe2" name="pe2">
                        <useroperator declaration="b4"/>
                    </partitionelement>
                    <partitionelement id="pe3" name="pe3">
                        <useroperator declaration="b5"/>
                        <useroperator declaration="b6"/>
                    </partitionelement>
                </partition>
                <partition id="P3" name="P3">
                    <usersort declaration="pluck2"/>
                    <partitionelement id="pe4" name="pe4">
                        <useroperator declaration="b4"/>
                        <useroperator declaration="b5"/>
                    </partitionelement>
                    <partitionelement id="pe5" name="pe5">
                        <useroperator declaration="b6"/>
                    </partitionelement>
                </partition>
            </declarations>
        </structure>
    </declaration>
    """

    ctx = PNML.Parser.parser_context()::PNML.ParseContext
    decl = parse_declaration!(ctx, node, pntd)
    @test typeof(decl) <: Declaration
    #@show PNML.partitionsorts(decldict(decl))
    #PNML.show_sorts(decldict(decl))

    # Examine 3 partition sorts
    for psort in values(PNML.partitionsorts(decldict(decl)))
        # partition -> partition element -> fe constant
        @test typeof(psort) <: PartitionSort # is a declaration
        @test PNML.isregistered(ctx.idregistry, PNML.pid(psort))
        psort == PNML.partitionsort(decldict(decl), PNML.pid(psort))
        @test Symbol(PNML.name(psort)) === pid(psort) # name and id are the same.
        partname = PNML.name(psort)
        partsort = PNML.Declarations.sortdefinition(psort)
        part_elements = PNML.sortelements(psort)::Vector{PartitionElement}

        for element in part_elements
            @test PNML.isregistered(ctx.idregistry, pid(element))
            @test PNML.Declarations.contains(element, :nosuch) == false
        end
        # println("partition $(repr(pid(psort))) $(repr(PNML.name(psort))) ",
        #     collect(PNML.Declarations.element_ids(psort)), " ",
        #     collect(PNML.Declarations.element_names(psort)))
        @test !isempty(PNML.Declarations.element_ids(psort))
        @test !isempty(PNML.Declarations.element_names(psort))
        PNML.Declarations.verify_partition(psort)
    end
end

@testset "arbitrary sort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <arbitrarysort id="id1" name="AGENT"/>
            </declarations>
        </structure>
    </declaration>
    """

    ctx = PNML.Parser.parser_context()::PNML.ParseContext
    decl = parse_declaration!(ctx, node, pntd)
    @test typeof(decl) <: Declaration
    #@show PNML.arbitrarysort(decldict(decl), :id1)
    @test name(PNML.arbitrarysort(decldict(decl), :id1)) == "AGENT"
    @test name(PNML.arbitrarysorts(decldict(decl))[:id1]) == "AGENT"
end
@testset "arbitrary sort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="dot2" name="SecondDot"> <dot/> </namedsort>
                <namedsort id="dot2" name="SecondDot"> <dot/> </namedsort>
            </declarations>
        </structure>
    </declaration>
    """
    ctx = PNML.Parser.parser_context()::PNML.ParseContext
    @test_throws DuplicateIDException parse_declaration!(ctx, node, pntd)
end


const nonsimple_sorts = (MultisetSort, ProductSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort)


# function _subtypes(type::Type)
#     out = Any[]
#     _subtypes!(out, type)
# end

function _subtypes!(out, type::Type)
    if !isabstracttype(type)
        push!(out, type)
    else
        foreach(Base.Fix1(_subtypes!, out), subtypes(type))
    end
    return out
end
function _sorts()
    out = Any[]
    _subtypes!(out, AbstractSort)
end

@testset "equal sorts" begin
    println("============================")
    println(" TODO equal sorts: $(_sorts())")
    println("============================")
    #TODO PartitionSort is confused - a SortDeclaration
    # for s in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     println(s)
    #     a = s()
    #     b = s()
    #     @test PNML.Sorts.equals(a, a)
    # end

    # for sorta in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     for sortb in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #         a = sorta()
    #         b = sortb()
    #         #println(repr(a), " == ", repr(b), " --> ", PNML.Sorts.equals(a, b), ", ", (a == b))
    #         sorta != sortb && @test a != b && !PNML.Sorts.equals(a, b)
    #         sorta == sortb && @test PNML.Sorts.equals(a, b)::Bool && (a == b)
    #     end
    # end

    #TODO Add tests for enumerated sorts, et al., with content.
    # MultisetSort
    # println("""

    # for sorta in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     for sortb in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #         a = PNML.MultisetSort(sorta())
    #         b = PNML.MultisetSort(sortb())
    #         sorta != sortb && @test a != b && !PNML.equals(a, b)
    #         sorta == sortb && @test PNML.equals(a, b)::Bool && (a == b)
    #     end
    # end
    # """)
    println("============================")
end

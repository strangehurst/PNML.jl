#function test_malformed(xml, ::Type{E}, emsg) where {E <: PNML.PnmlException} 

"Parse xml and expect a MalformedException with message containing `emsg`."
function test_malformed(emsg, xml)
    try
        n  = parse_node(to_node(xml))
        error("expected exception message containing '$emsg` from \n$xml")
    catch e
        if e isa PNML.PnmlException
            @test e isa  PNML.MalformedException
            @test occursin(emsg, e.msg)
        else
            rethrow(e)
        end
    finally
            PNML.reset_registry()
    end    
end

function test_warn(emsg, xml)
    try
        @test_logs (:warn, emsg)  parse_node(to_node(xml))
    finally
        PNML.reset_registry()
    end
end


@testset "missing namespace" begin
    test_warn(r"missing namespace",
                   """
     <?xml version="1.0" encoding="UTF-8"?>
        <pnml>
        </pnml>
            """)
    test_warn(r"missing namespace", """<?xml version="1.0" encoding="UTF-8"?> <pnml> </pnml> """)
    test_warn(r"missing namespace", """<?xml version="1.0" encoding="UTF-8"?> <pnml/> """)
end

@testset "name" begin
    test_warn(r"missing <text>", """<name> </name>""")
end

@testset "malformed" begin
    test_malformed("missing tool attribute",
                   """
     <?xml version="1.0" encoding="UTF-8"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
          <net type="http://www.pnml.org/version-2009/grammar/pnmlcore" id="n1">
            <page id="pg1">
              <place id="p1"/>
              <transition id="t1"/>
              <place id="p3"/>
              <place id="p4"/>
              <place id="p5">
                <toolspecific/>
              </place>
              <place id="p6">
                <toolspecific/>
              </place>
            </page>
          </net>
        </pnml>
            """)

    test_malformed("net missing type",
                   """
     <?xml version="1.0" encoding="UTF-8"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
          <net id="4712">
            <page id="3">
              <place id="p2">
                <toolspecific/>
              </place>
              <arc id="a3" source="p2" target="t3"/>
              <transition id="t3"/>
            </page>
          </net>
        </pnml>
        """)

       test_malformed("net missing type",
               """<net id="4712"> </net>""")

    # test absence of an exception
    @test_throws Exception test_malformed("not malformed here",
           """<toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0"> <visible>true</visible> </toolspecific>""")

    test_malformed("missing version attribute",
           """<toolspecific tool="de.uni-freiburg.telematik.editor"> <visible>true</visible> </toolspecific>""")

    test_malformed("missing tool attribute",
           """<toolspecific version="1.0"> <visible>true</visible> </toolspecific>""")
end

@testset "missing id" begin
    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <net type="test" > </net>""")))

    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <page type="test" > </page>""")))

    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <place> </place>""")))

    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <transition> </transition>""")))

    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <arc> </arc>""")))

    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <referencePlace> </referencePlace>""")))

    @test_throws PNML.MissingIDException parse_node(root(EzXML.parsexml("""
        <referenceTransition> </referenceTransition>""")))
end

@testset "graphics" begin
    test_malformed("missing x","""<graphics><offset y="2" /></graphics>""")
    test_malformed("missing y","""<graphics><offset x="1" /></graphics>""")

    test_malformed("missing x","""<graphics><position  y="2" /></graphics>""")
    test_malformed("missing y","""<graphics><position  x="1" /></graphics>""")

    test_malformed("missing x","""<graphics><dimension  y="2" /></graphics>""")
    test_malformed("missing y","""<graphics><dimension  x="1" /></graphics>""")

    #test_malformed("missing y","""<graphics></graphics>""")
    
    test_malformed("missing x",""" <tokengraphics><tokenposition y="-2"/></tokengraphics>""")
    test_malformed("missing y",""" <tokengraphics><tokenposition x="-9"/></tokengraphics>""")
    #test_malformed("missing  ",""" <tokengraphics><tokenposition x="-9" y="-2"/></tokengraphics>""")

    #test_malformed("missing y",""" """)
end

@testset "node_summary" begin
    @test true
    xml = readxml("data/simple.pnml").root
    PRINT_PNML && node_summary(xml, n=2)
    
    # Print 1st 5 lines.
    io1 = IOBuffer()
    node_summary(io1, xml)
    s1 = strip(String(take!(io1)))

    io2 = IOBuffer()
    node_summary(io2, xml; n=2)
    s2 = strip(String(take!(io2)))

    io3 = IOBuffer()
    node_summary(io3, xml; pp=EzXML.prettyprint)
    s3 = strip(String(take!(io3)))

    io4 = IOBuffer()
    node_summary(io4, xml; pp=AbstractTrees.print_tree)
    s4 = strip(String(take!(io4)))
    
    @test endswith(s1,"...")
    @test endswith(s2,"...")
    @test endswith(s3,"...")
    @test endswith(s4,"...")
    suffix = '.'
    s1=rstrip(s1,suffix)
    s2=rstrip(s2,suffix)
    s3=rstrip(s3,suffix)
    s4=rstrip(s4,suffix)
    
    @test length(s1) >= length(s2)
    @test startswith(replace(s1, r"\s+"=>" "),replace(s2, r"\s+"=>" "))
    @test s1 == s3
    @test s1 != s4
end

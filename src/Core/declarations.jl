"""
$(TYPEDEF)
$(TYPEDFIELDS)
Label of a <net> or <page> that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.
Other PNTDs may introduce non-standard uses for declarations.

# Notes: `declarations` is implemented as a collection of `Any`.
We can use infrastructure implemented for HL nets to provide nonstandard extensions.
"""
struct Declaration <: Annotation
    declarations::Vector{Any} #TODO Type parameter? Seperate vector for each type?
    #SortDeclarations               xml:"structure>declarations>namedsort"`
	#PartitionSortDeclarations      xml:"structure>declarations>partition"
	#VariableDeclarations           xml:"structure>declarations>variabledecl"
	#OperatorDeclarations           xml:"structure>declarations>namedoperator"
	#PartitionOperatorsDeclarations xml:"structure>declarations>partitionelement"
	#FEConstantDeclarations         xml:"structure>declarations>feconstant"

    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Vector{ToolInfo}
    xml::Maybe{XMLNode}
end

Declaration() = Declaration(Any[], nothing, ToolInfo[], nothing)

declarations(d::Declaration) = d.declarations
xmlnode(d::Declaration) = d.xml

#TODO Document/implement/test collection interface of Declaration.
Base.length(d::Declaration) = (length ∘ declarations)(d)

# Flattening pages combines declarations & toolinfos into the first page.
function Base.append!(l::Declaration, r::Declaration)
    append!(declarations(l), declarations(r))
end

function Base.empty!(d::Declaration)
    empty!(declarations(d))
end

# Intermediate Representation

The intermediate representation (IR) is between the XML model and
a "usable" network. Many different flavors of Petri Nets are expected 
to be implemented using the IR.

The IR is constructed by traversing the XML and using the tag name as keys.

The structure of the IR follows the tree structure of a well-formed XML document
and the PNML specification.

The crude structure required by the pnmlcore schema:
Document
  - Net
    - Page
    	- Places, Marking
    	- Transitions, Condition
    	- Arcs, Inscription
    	- Toolinfos 
    	- Labels
    	- Subpages
    - Name
	- Toolinfos
	- Labels
	
The IR is implemented under the assumption the the input pnml file is valid.
All tags are assumed to be meaningful to the resulting network.
The pnmlcore schema requires all undefined tags will be considered pnml labels.
The IR is capable of handling arbitrary labels.
Many label tags from higherlevel pnml schemas are recognized by the IR parsers.

While the Petri Net Type Definition (pntd) is present in every valid net,
it was not necessary to consult the type during creation of the IR. 
It is expected that conforming to pntd will be done at a higher level.

Some parts of pnml are complicated. Parts that are not yet completed
may hold unparsed XML. In fact, parts of pnml are specified as holding 
any well-formed XML.

Between the tags explicitly handled by the IR and the generic label collection
the higher level network 

# History of this IR

Started as nested Dict{Symbol,Any} see [`PnmlDict`](@ref PNML.PnmlDict). 

2021-12-15, Began the process of moving to a struct-based scheme 
based on [`Pnml`](@ref PNML.Pnml) and the rest of the intermediate representation.

Some instances of `PnmlDict` are still present in the parsing mechanism.

As experience with building & using more complicated pnml network models,
more of the IR will be implemented or changed.



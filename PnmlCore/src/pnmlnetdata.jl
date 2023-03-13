"""
Collect the `Page`s, `PnmlNodes`s, `Arc`s of a Petri Net Graph (s).
Accessed via pnml ID keys or iterate over values of a dictionary. See `OrderedDict`.
"""
struct PnmlNetData{PNTD <: PnmlType, PG,PL,TR,AR,RP,RT} #! was {PNTD <: PnmlType, M, I, C, S}
    page::PG          # OrderedDict{Symbol, Page{PNTD,M,I,C,S}}
    place::PL         # OrderedDict{Symbol, Place{PNTD,M,S}}
    transition::TR    # OrderedDict{Symbol, Transition{PNTD,C}}
    arc::AR           # OrderedDict{Symbol, Arc{PNTD,I}}
    refplace::RP      # OrderedDict{Symbol, RefPlace{PNTD}}
    reftransition::RT # OrderedDict{Symbol, RefTransition{PNTD}}
end

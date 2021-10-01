"""
"""
function validate_node(node)
    #@debug "validate_node($(node.name)) -> $(verifymap[node.name])"
    verifymap[node.name](node)
end

"""
    Check the <pnml> element against TODO.
Return TODO
"""
function validate_pnml(node)
    #TODO check namespace, error or warn on mismatch
end

function validate_net(node) end
function validate_page(node) end
function validate_place(node) end
function validate_transition(node) end
function validate_arc(node) end
#function validate_(node) end


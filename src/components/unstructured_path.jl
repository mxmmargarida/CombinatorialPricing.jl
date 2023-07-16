# Function to convert a solution x to a path without structure
function unstructured_path(dpgraph::DPGraph, x_set::BitSet)
    _nl = nl(dpgraph)
    current = source_node(dpgraph)
    sink = sink_node(dpgraph)
    arcs = arc_type(dpgraph)[]

    for l in 1:_nl
        # Action is the set of selected items within the current layer
        action = partition(dpgraph, l) ∩ x_set
        next = transition(dpgraph, current, action)
        (l == _nl) && @assert(next == sink)
        push!(arcs, DPArc(current, next, action))
        current = next
    end

    return arcs
end

unstructured_path(dpgraph::DPGraph, x::Vector{<:Number}) = unstructured_path(dpgraph, convert_x_to_set(x))

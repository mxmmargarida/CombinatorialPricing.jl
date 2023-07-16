# Function to convert a solution x to a path in a predefined structure
function structured_path(dpgraph::DPGraph, x_set::BitSet)
    layers, partition = dpgraph.layers, dpgraph.partition
    _nl = nl(dpgraph)
    source = source_node(dpgraph)
    # Build a graph with all feasible paths then find the longest path
    # Dynamic programming: forward pass
    dists = Dict(source => 0)
    parents = Dict(source => source)
    # Avoid reallocating "action" to save time
    _actions = [intersect!(union_sets(@view partition[(ll+1):l]), x_set) for ll in 0:_nl-1, l in 1:_nl]

    for l in 1:_nl
        for s in layers[l]
            current = (l, s)
            s_dist, s_parent = typemin(Int), current
            for (prev, dist) in dists
                (prev[1] < l) || continue                   # Must be in some previous layer
                (dist >= 0 && dist >= s_dist) || continue   # Must have a promising distance
                # Extract the action
                action = _actions[prev[1]+1, l]
                # Check if the transition is valid
                is_valid_transition(dpgraph, prev, current, action) || continue
                # Update longest distance to s
                if dist + 1 > s_dist
                    s_dist, s_parent = dist + 1, prev
                end
            end
            dists[current] = s_dist
            parents[current] = s_parent
        end
    end
    # Backtracking
    arcs = DPArc[]
    begin
        current = sink_node(dpgraph)
        for _ in 1:_nl
            prev = parents[current]
            action = _actions[prev[1]+1, current[1]]
            push!(arcs, DPArc(prev, current, action))
            current = prev
            (current[1] == 0) && break
        end
        @assert(current[1] == 0)
    end
    return reverse!(arcs)
end

structured_path(dpgraph::DPGraph, x::Vector{<:Number}) = structured_path(dpgraph, convert_x_to_set(x))

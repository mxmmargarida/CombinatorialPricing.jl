function populate_nodes!(dpgraph::DPGraph, solutions::Vector{BitSet}; num_nodes=nothing, include_arcs=true)
    layers, arcs = dpgraph.layers, dpgraph.arcs

    all_nodes = DPNode[]

    # Get the nodes from solutions
    for sol in solutions
        path = unstructured_path(dpgraph, sol)
        append!(all_nodes, dst.(path))
    end

    # Filter nodes based on frequency
    if isnothing(num_nodes)
        unique!(all_nodes)
    else
        freq = countmap(all_nodes)
        num_nodes = min(num_nodes, length(freq))
        all_nodes = first.(sort(collect(freq), by=last, rev=true))[1:num_nodes]
    end

    # Add the nodes to corresponding layers
    for (l, s) in all_nodes
        push!(layers[l], s)
    end
    unique!.(layers)

    # Add arcs from given solutions
    if include_arcs
        for sol in solutions
            if isnothing(num_nodes)
                append!(arcs, unstructured_path(dpgraph, sol))
            else
                append!(arcs, structured_path(dpgraph, sol))
            end
        end
    end
    unique!(arcs)

    return dpgraph
end

function populate_arcs!(dpgraph::DPGraph, solutions::Vector{BitSet})
    arcs = dpgraph.arcs

    for sol in solutions
        path = structured_path(dpgraph, sol)
        append!(arcs, path)
    end

    unique!(arcs)
    return dpgraph
end

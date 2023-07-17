function populate_nodes!(dpgraph::DPGraph, solutions::Vector{BitSet}; include_arcs=true)
    layers, arcs = dpgraph.layers, dpgraph.arcs

    for sol in solutions
        path = unstructured_path(dpgraph, sol)
        nodes = last.(dst.(path))
        push!.(layers, nodes)
        include_arcs && append!(arcs, path)
    end

    unique!.(layers)
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

function unique_paths(dpgraph::DPGraph)
    A = arc_type(dpgraph)
    path_dict = Dict{BitSet,Vector{A}}()
    source, sink = source_node(dpgraph), sink_node(dpgraph)

    out_dict = MultiDict()
    for a in dpgraph.arcs
        push!(out_dict, src(a) => a)
    end

    function recur(merged, path)
        n = dst(merged)
        if n == sink
            # Conclude if sink is reached
            sol = action(merged)
            # Replace the old path if this path has more arcs
            old_path = get!(path_dict, sol, path)
            (length(path) > length(old_path)) && (path_dict[sol] = path)
        else
            # If not, concatenate the next arc
            for a in out_dict[n]
                recur(merge(merged, a), vcat(path, a))
            end
        end
    end

    recur(DPArc(source, source, BitSet()), A[])
    return collect(values(path_dict))
end

function unique_arcs(dpgraph::DPGraph)
    paths = Set.(unique_paths(dpgraph))
    arcs = reduce(union!, paths)
    return collect(arcs)
end

count_unique_paths(dpgraph::DPGraph) = length(unique_paths(dpgraph))

function unique_graph(dpgraph::DPGraph)
    @unpack prob, partition, layers = dpgraph
    arcs = unique_arcs(dpgraph)
    return DPGraph(prob, partition, layers, arcs)
end

function node_stats(dpgraph::DPGraph)
    ins = Dict()
    outs = Dict()
    for l in 0:nl(dpgraph), s in layer(dpgraph, l)
        ins[(l, s)] = 0
        outs[(l, s)] = 0
    end
    for a in dpgraph.arcs
        ins[dst(a)] += 1
        outs[src(a)] += 1
    end
    ins[source_node(dpgraph)] += 1
    outs[sink_node(dpgraph)] += 1

    df = DataFrame(node=DPNode[], ins=Int[], outs=Int[])
    for node in keys(ins)
        push!(df, (node, ins[node], outs[node]))
    end
    df.arcs = df.ins .+ df.outs
    df.connections = df.ins .* df.outs

    return df
end

function count_paths(dpgraph::DPGraph)
    arcs = sort(dpgraph.arcs, by=a->src(a)[1])
    np = Dict{DPNode,Float64}(source_node(dpgraph) => 1.)
    for a in arcs
        s, d = src(a), dst(a)
        np[d] = get(np, d, 0.) + get(np, s, 0.)
    end
    dest = sink_node(dpgraph)
    return get(np, dest, 0.)
end

function arc_distribution(arcs::Vector{<:DPArc})
    n = maximum(a -> dst(a)[1], arcs)
    M = zeros(Int, n+1, n+1)
    for a in arcs
        s, d = src(a)[1], dst(a)[1]
        M[s+1, d+1] += 1
    end
    return M
end
arc_distribution(dpgraph::DPGraph) = arc_distribution(dpgraph.arcs)

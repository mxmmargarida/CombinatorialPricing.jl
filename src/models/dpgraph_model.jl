function dpgraph_model(dpgraph::DPGraph; silent=false, threads=nothing, heuristic=true, sdtol=1e-4,
    reset_follower=false, trivial_cuts=false, trivial_bound=false)

    model = base_model(dpgraph.prob; silent, threads, sdtol, trivial_cuts, trivial_bound)
    add_dpgraph_dual!(model, dpgraph)
    heuristic && add_heuristic_provider!(model)
    add_dpgraph_callback!(model; threads, reset_follower)
    return model
end

function add_dpgraph_dual!(model, dpgraph::DPGraph)
    prob = model[:prob]
    model[:dpgraph] = dpgraph
    ct = make_ct(model[:t], prob)

    # Variables correspond to nodes
    nodes = collect(vertices(dpgraph))
    @variable(model, y[nodes])
    fix(y[sink_node(dpgraph)], 0)
    
    # Constraints are arcs in the DP graph
    for arc in edges(dpgraph)
        @constraint(model, y[src(arc)] - y[dst(arc)] ≤ sum(ct[i] for i in action(arc); init=0.))
    end

    # Dual objective = max y[source] (- y[sink])
    @constraint(model, dualobj, model[:g] == y[source_node(dpgraph)])
end

function add_dpgraph_callback!(model; threads=nothing, reset_follower=false)
    dpgraph = model[:dpgraph]
    y = model[:y]
    ct = make_ct(model[:t], model[:prob])

    add_cutting_plane_callback!(model; threads, reset_follower) do cb_data, x̂
        x_set = convert_x_to_set(x̂)
        path = structured_path(dpgraph, x_set)
        for a in path
            # We need to re-add the constraint even if it exists because there's no guarantee that it is included
            con = @build_constraint(y[src(a)] - y[dst(a)] ≤ sum(ct[i] for i in action(a); init=0.))
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)
            (a in dpgraph.arcs) || push!(dpgraph.arcs, a)
        end
    end
end

function dpgraph_model(dpgraph::DPGraph; silent=false, threads=nothing, heuristic=true, sdtol=1e-4)
    model = base_model(dpgraph.prob; silent, threads)
    add_dpgraph_dual!(model, dpgraph; sdtol)
    heuristic && add_heuristic_provider!(model)
    add_dpgraph_callback!(model; threads)
    return model
end

function add_dpgraph_dual!(model, dpgraph::DPGraph; sdtol=1e-4)
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

    # Primal objective = min (c + t)x
    # Dual objective = max y[source] (- y[sink])
    primal_obj = model[:f]
    dual_obj = y[source_node(dpgraph)]
    @constraint(model, strongdual, primal_obj ≤ dual_obj + sdtol)
end

function add_dpgraph_callback!(model; threads=nothing)
    dpgraph = model[:dpgraph]
    y = model[:y]
    ct = make_ct(model[:t], model[:prob])

    add_cutting_plane_callback!(model; threads) do cb_data, x̂
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

function colgen_model(dpgraph::DPGraph, num_cols; silent=false, threads=nothing, heuristic=true, sdtol=1e-4,
    reset_follower=false, trivial_cuts=false, trivial_bound=false, filter = (in, out) -> true)

    # Note: dpgraph must be empty
    model = base_model(dpgraph.prob; silent, threads, sdtol, trivial_cuts, trivial_bound)
    add_colgen_dual!(model, dpgraph, num_cols; threads)
    heuristic && add_heuristic_provider!(model)
    add_colgen_callback!(model; threads, reset_follower, filter)
    return model
end

function add_colgen_dual!(model, dpgraph::DPGraph, num_cols; threads=nothing)
    prob = model[:prob]
    model[:dpgraph] = dpgraph
    n = num_items(prob)
    ct = make_ct(model[:t], prob)

    # A pool of nodes, 1 is always the source, 2 is the sink
    @variable(model, y[1:num_cols])
    fix(y[2], 0)

    # Dual objective = max y[source] (- y[sink])
    @constraint(model, dualobj, model[:g] == y[1])
end

function add_colgen_callback!(model; threads=nothing, reset_follower=false, filter = (in, out) -> true)
    dpgraph = model[:dpgraph]
    y = model[:y]
    ct = make_ct(model[:t], model[:prob])

    model[:cgstate] = cgstate = ColGenModelState(length(y), filter, dpgraph)

    add_cutting_plane_callback!(model; threads, reset_follower) do cb_data, x̂
        x_set = convert_x_to_set(x̂)

        if !_is_full(cgstate)
            # If new nodes can be added, find the unstructured path and add it to the proto-graph
            upath = unstructured_path(dpgraph, x_set)
            _add_proto!(cgstate, upath)
            # Add new nodes if necessary
            nodes = _get_new_nodes(cgstate, upath)
            _realize!(cgstate, nodes)
        end

        # Fit the solution to the graph
        path = structured_path(dpgraph, x_set)

        # Add all arcs along the path
        for a in path
            # We need to re-add the constraint even if it exists because there's no guarantee that it is included
            con = @build_constraint(y[cgstate[src(a)]] - y[cgstate[dst(a)]] ≤ sum(ct[i] for i in action(a); init=0.))
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)
            (a in dpgraph.arcs) || push!(dpgraph.arcs, a)
        end
    end
end

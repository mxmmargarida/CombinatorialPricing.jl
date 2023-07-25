function colgen_model(dpgraph::DPGraph, num_cols; silent=false, threads=nothing, heuristic=true, sdtol=1e-4, min_connections=2)
    # Note: dpgraph must be empty
    model = base_model(dpgraph.prob; silent, threads, sdtol)
    add_colgen_dual!(model, dpgraph, num_cols; threads)
    heuristic && add_heuristic_provider!(model)
    add_colgen_callback!(model; threads, min_connections)
    return model
end

function add_colgen_dual!(model, dpgraph::DPGraph, num_cols; threads=nothing)
    prob = model[:prob]
    model[:dpgraph] = dpgraph
    n = num_items(prob)
    ct = make_ct(model[:t], prob)

    # A pool of nodes, 1 is always the source, 2 is the sink
    @variable(model, y[1:num_cols])
    push!(dpgraph.layers[end], sink_state(dpgraph))
    fix(y[2], 0)

    # Connections to prevent unboundedness
    tollfree = toll_free_solution(prob; threads)
    @constraint(model, y[1] ≤ ct' * convert_set_to_x(tollfree, n))

    nulltoll = null_toll_solution(prob; threads)
    @constraint(model, y[1] ≤ ct' * convert_set_to_x(nulltoll, n))

    # Dual objective = max y[source] (- y[sink])
    @constraint(model, dualobj, model[:g] == y[1])
end

function add_colgen_callback!(model; threads=nothing, min_connections=2)
    dpgraph = model[:dpgraph]
    y = model[:y]
    ct = make_ct(model[:t], model[:prob])

    model[:cgstate] = cgstate = ColGenModelState(length(y), min_connections, dpgraph)

    add_cutting_plane_callback!(model; threads) do cb_data, x̂
        x_set = convert_x_to_set(x̂)

        local path
        if _is_full(cgstate)
            # If no nodes can be added, find the structured path
            path = structured_path(dpgraph, x_set)
        else
            # If new nodes can be added, find the unstructured path and add it to the proto-graph
            upath = unstructured_path(dpgraph, x_set)
            _add_proto!(cgstate, upath)
            # Add new nodes if necessary
            nodes = _get_new_nodes(cgstate, upath)
            _realize!(cgstate, nodes)
            # Refit the path to the new graph
            path = _refit(cgstate, upath)
        end

        # Add all arcs along the path
        for a in path
            # We need to re-add the constraint even if it exists because there's no guarantee that it is included
            con = @build_constraint(y[cgstate[src(a)]] - y[cgstate[dst(a)]] ≤ sum(ct[i] for i in action(a); init=0.))
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)
            (a in dpgraph.arcs) || push!(dpgraph.arcs, a)
        end
    end
end

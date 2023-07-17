function colgen_model(dpgraph::DPGraph, num_cols; silent=false, threads=nothing, heuristic=true, sdtol=1e-4)
    model = base_model(dpgraph.prob; silent, threads)
    add_colgen_dual!(model, dpgraph, num_cols; sdtol)
    heuristic && add_heuristic_provider!(model)
    add_colgen_callback!(model; threads)
    return model
end

function add_colgen_dual!(model, dpgraph::DPGraph, num_cols; threads=nothing, sdtol=1e-4)
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

    # Primal objective = min (c + t)x
    # Dual objective = max y[source] (- y[sink])
    primal_obj = model[:f]
    dual_obj = y[1]
    @constraint(model, strongdual, primal_obj ≤ dual_obj + sdtol)
end

function add_colgen_callback!(model; threads=nothing)
    dpgraph = model[:dpgraph]
    y = model[:y]
    num_cols = length(y)
    ct = make_ct(model[:t], model[:prob])

    node_to_ind = model[:cg_node_to_ind] = Dict([
        source_node(dpgraph) => 1,
        sink_node(dpgraph) => 2
    ])

    # Automatically create new node when it does not exist
    function get_node_var(node)
        if !haskey(node_to_ind, node)
            node_to_ind[node] = length(node_to_ind) + 1
            push!(dpgraph.layers[node[1]], node[2])
        end
        return y[node_to_ind[node]]
    end

    add_cutting_plane_callback!(model; threads) do cb_data, x̂
        x_set = convert_x_to_set(x̂)

        # Check if there are enough nodes to fit the path
        path = unstructured_path(dpgraph, x_set)
        unstruct_nodes = Set(vcat(src.(path), dst.(path)))
        num_new_nodes = count(n -> !haskey(node_to_ind, n), unstruct_nodes)

        # If not fit, find the structured path instead
        if num_new_nodes > num_cols - length(node_to_ind)
            path = structured_path(dpgraph, x_set)
        end

        # Add all arcs along the path
        for a in path
            # We need to re-add the constraint even if it exists because there's no guarantee that it is included
            con = @build_constraint(get_node_var(src(a)) - get_node_var(dst(a)) ≤ sum(ct[i] for i in action(a); init=0.))
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)
            (a in dpgraph.arcs) || push!(dpgraph.arcs, a)
        end
    end
end

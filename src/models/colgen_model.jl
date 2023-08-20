function colgen_model(dpgraph::DPGraph, num_cols; silent=false, threads=nothing, heuristic=true, sdtol=1e-4,
    reset_follower=false, trivial_cuts=false, trivial_bound=false, filter = (in, out) -> true)

    # Note: dpgraph must be empty
    model = base_model(dpgraph.prob; silent, threads, sdtol, trivial_cuts, trivial_bound)
    add_dpgraph_dual!(model, dpgraph)
    add_colgen_dual!(model, dpgraph, num_cols; filter)
    heuristic && add_heuristic_provider!(model)
    add_colgen_callback!(model; threads, reset_follower)
    return model
end

function add_colgen_dual!(model, dpgraph::DPGraph, num_cols; filter = (in, out) -> true)
    model[:dpgraph] = dpgraph
    model[:cgstate] = ColGenModelState(num_cols, filter, dpgraph)

    # A pool of nodes
    @variable(model, zz[1:num_cols])

    # Map existing and potential nodes to a single array
    z = model[:z] = VariableRef[]
    append!(z, model[:y].data)
    append!(z, zz)
end

function add_colgen_callback!(model; threads=nothing, reset_follower=false)
    dpgraph = model[:dpgraph]
    cgstate = model[:cgstate]
    z = model[:z]
    ct = make_ct(model[:t], model[:prob])

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
            con = @build_constraint(z[cgstate[src(a)]] - z[cgstate[dst(a)]] ≤ sum(ct[i] for i in action(a); init=0.))
            MOI.submit(model, MOI.LazyConstraint(cb_data), con)
            (a in dpgraph.arcs) || push!(dpgraph.arcs, a)
        end
    end
end

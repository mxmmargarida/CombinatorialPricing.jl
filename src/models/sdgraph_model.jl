function sdgraph_model(sdgraph::SDGraph; silent=false, threads=nothing, heuristic=true, sdtol=1e-4,
    reset_follower=false)

    model = base_model(sdgraph.prob; silent, threads, sdtol)
    add_sdgraph_dual!(model, sdgraph)
    heuristic && add_heuristic_provider!(model)
    add_sdgraph_callback!(model; threads, reset_follower)
    return model
end

function add_sdgraph_dual!(model, sdgraph::SDGraph)
    prob = model[:prob]
    model[:sdgraph] = sdgraph
    ct = make_ct(model[:t], prob)

    # Variables correspond to nodes
    nodes = collect(vertices(sdgraph))
    @variable(model, y[nodes])
    fix(y[sink_node(sdgraph)], 0)

    # Constraints are arcs in the DP graph
    for arc in edges(sdgraph)
        @constraint(model, y[src(arc)] - y[dst(arc)] ≤ sum(ct[i] for i in action(arc); init=0.0))
    end

    # Dual objective = max y[source] (- y[sink])
    @constraint(model, dualobj, model[:g] == y[source_node(sdgraph)])
end

function add_sdgraph_callback!(model; threads=nothing, reset_follower=false)
    sdgraph = model[:sdgraph]
    y = model[:y]
    ct = make_ct(model[:t], model[:prob])

    function add_arc(cb_data, arc)
        con = @build_constraint(y[src(arc)] - y[dst(arc)] ≤ sum(ct[i] for i in action(arc); init=0.0))
        MOI.submit(model, MOI.LazyConstraint(cb_data), con)
        (arc in sdgraph.arcs) || push!(sdgraph.arcs, arc)
    end

    add_cutting_plane_callback!(model; threads, reset_follower) do cb_data, x
        x_set = convert_x_to_set(x)
        added = false

        for l in 2:-1:1
            states = shuffle(sdgraph.layers[l])
            for s in states
                (s.selected ⊆ x_set) || continue
                rest = setdiff(x_set, s.selected)
                add_arc(cb_data, SDArc((l, s), sink_node(sdgraph), rest))
                added = true
                break
            end
            added && break
        end

        # In the worst case, we add a value function cut
        added || add_arc(cb_data, SDArc(source_node(sdgraph), sink_node(sdgraph), x_set))
    end
end

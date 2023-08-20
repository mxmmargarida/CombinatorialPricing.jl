struct ColGenModelState
    num_cols::Int
    filter::Function
    dpgraph::DPGraph
    node_to_ind::Dict{DPNode,Int}
    proto_ins::MultiDict{DPNode, DPArc}
    proto_outs::MultiDict{DPNode, DPArc}
end

function ColGenModelState(num_cols, filter, dpgraph)
    nodes = collect(vertices(dpgraph))
    node_to_ind = Dict(reverse.(enumerate(nodes)))

    proto_ins = MultiDict{DPNode, DPArc}()
    proto_outs = MultiDict{DPNode, DPArc}()
    for arc in edges(dpgraph)
        s, d = src(arc), dst(arc)
        push!(proto_outs, s => arc)
        push!(proto_ins, d => arc)
    end

    return ColGenModelState(num_cols + length(nodes), filter, dpgraph, node_to_ind, proto_ins, proto_outs)
end

# Check if the node budget has reached
_is_full(cgstate::ColGenModelState) = length(cgstate.node_to_ind) >= cgstate.num_cols

Base.getindex(cgstate::ColGenModelState, node::DPNode) = cgstate.node_to_ind[node]

# Add an unstructued path to the proto ins/outs dicts
function _add_proto!(cgstate::ColGenModelState, path)
    @unpack proto_ins, proto_outs = cgstate
    for arc in path
        s, d = src(arc), dst(arc)
        push!(proto_outs, s => arc)
        push!(proto_ins, d => arc)
        unique!(proto_outs[s])
        unique!(proto_ins[d])
    end
end

# Get the list of new nodes along a path that are not added to dpgraph
function _get_new_nodes(cgstate::ColGenModelState, path)
    @unpack node_to_ind, proto_ins, proto_outs = cgstate

    # Get the list of nodes along the path and filter out source/sink
    nodes = dst.(path)  # Exclude the source
    pop!(nodes)         # Remove the sink

    # Return the nodes that pass the filter
    return filter(nodes) do node
        haskey(node_to_ind, node) && return false       # Must not be in dpgraph
        return cgstate.filter(length(proto_ins[node]), length(proto_outs[node]))
    end
end

# Add the new nodes and arcs
function _realize!(cgstate::ColGenModelState, nodes; apply_unique=true)
    @unpack num_cols, dpgraph, node_to_ind, proto_ins, proto_outs = cgstate
    @unpack layers, arcs = dpgraph

    # Search all paths connecting root to nodes existing in dpgraph
    # Each path is described by a single merged arc
    # The direction depends on other parameters
    function search_paths(root, proto_dict, next, merge)
        all_paths = DPArc[]

        function search_recur(a)
            for b in proto_dict[next(a)]
                c = merge(a, b)
                if haskey(node_to_ind, next(c))
                    push!(all_paths, c)
                else
                    search_recur(c)
                end
            end
        end

        search_recur(DPArc(root, root, BitSet()))
        return all_paths
    end

    # Utilities
    search_forward(root) = search_paths(root, proto_outs, dst, merge)
    search_backward(root) = search_paths(root, proto_ins, src, (a, b) -> merge(b, a))

    # Add nodes
    added_nodes = DPNode[]
    for node in nodes
        (length(node_to_ind) < num_cols) || break       # Break if node budget has reached
        # Add node to both registry and dpgraph
        node_to_ind[node] = length(node_to_ind) + 1
        @debug "Realize $(node => node_to_ind[node])"
        push!(layers[node[1]], node[2])
        push!(added_nodes, node)
    end

    # Add arcs
    for node in added_nodes
        append!(arcs, search_forward(node))
        append!(arcs, search_backward(node))
    end

    apply_unique && unique!(arcs)
    return added_nodes
end

# Refit the unstructured path to the current dpgraph
function _refit(cgstate::ColGenModelState, path)
    @unpack node_to_ind, dpgraph = cgstate

    source = source_node(dpgraph)
    a = DPArc(source, source, BitSet())
    refit = empty(path)

    for b in path
        # Merge with the previous arcs
        a = merge(a, b)
        n = dst(a)
        # Reset if the node appears in dpgraph
        if haskey(node_to_ind, n)
            push!(refit, a)
            a = DPArc(n, n, BitSet())
        end
    end

    return refit
end

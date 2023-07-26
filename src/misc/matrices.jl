function incidence_matrix(g::SimpleGraph)
    mat = spzeros(Int, nv(g), ne(g))
    for (i, e) in enumerate(edges(g))
        mat[src(e), i] = 1
        mat[dst(e), i] = 1
    end
    return mat
end

function incidence_matrix(sets::Vector{BitSet}, num_elements::Int)
    mat = spzeros(Int, num_elements, length(sets))
    for (j, s) in enumerate(sets)
        for i in s
            mat[i, j] = 1
        end
    end
    return mat
end

function incidence_matrix(g::SimpleGraph)
    mat = spzeros(Int, nv(g), ne(g))
    for (i, e) in enumerate(edges(g))
        mat[src(e), i] = 1
        mat[dst(e), i] = 1
    end
    return mat
end

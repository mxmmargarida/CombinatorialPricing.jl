function plot_solution(prob::MaxStableSetPricing, x_set::BitSet)
    g = graph(prob)
    n, i1 = nv(g), tolled(prob)

    nodelabel = string.(1:n)
    nodesize = 0.25/sqrt(n)
    nodestrokec = [i ∈ x_set ? colorant"red" : nothing for i in 1:n]
    nodefillc = [i ∈ i1 ? colorant"orange" : colorant"gray" for i in 1:n]

    gplot(g; nodelabel, nodesize, nodestrokec, nodefillc, nodestrokelw=1.)
end

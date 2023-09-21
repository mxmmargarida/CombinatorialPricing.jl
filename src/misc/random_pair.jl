function random_pair(rng::AbstractRNG, s::BitSet)
    (length(s) <= 1) && return s
    for _ in 1:100
        a, b = rand(rng, s, 2)
        (a != b) && return BitSet([a, b])
    end
    return s
end

random_pair(s::BitSet) = random_pair(Random.default_rng(), s)


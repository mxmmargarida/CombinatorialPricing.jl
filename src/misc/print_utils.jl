function bitset_braille(set::BitSet, n::Int)
    x = convert_set_to_x(set, ceil(Int, n/4) * 4)
    M = reshape(x, 4, :)
    return "[$(chomp(ustring(M)))]"
end

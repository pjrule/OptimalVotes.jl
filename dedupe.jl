function coords(idx::Int, s::Int)::Tuple
    row = ((idx - 1) ÷ s) + 1
    col = ((idx - 1) % s) + 1
    return (row, col)
end

function coord_index(row::Int, col::Int, s::Int)::Int
    s * (row - 1) + col
end

function rot(idx::Int, s::Int, angle::Int)::Int
    row, col = coords(idx, s)
    if angle == 0
        return idx
    elseif angle == 90
        rot_row = s + 1 - col
        rot_col = row
    elseif angle == 180
        rot_row = s + 1 - row
        rot_col = s + 1 - col
    elseif angle == 270
        rot_row = col
        rot_col = s + 1 - row
    else
        throw(DomainError(angle, "Angle must be 0º, 90º, 180º, or 270º"))
    end
    coord_index(rot_row, rot_col, s)
end

function rot(combo::AbstractArray, s::Int, angle::Int)::AbstractArray
    [rot(v, s, angle) for v in combo]
end

function reflect(idx::Int, s::Int, horizontal::Bool)::Int
    row, col = coords(idx, s)
    if horizontal
        ref_row = row
        ref_col = s + 1 - col
    else
        ref_row = s + 1 - row
        ref_col = col
    end
    coord_index(ref_row, ref_col, s)
end

function reflect(combo::AbstractArray, s::Int, horizontal::Bool)::AbstractArray
    [reflect(v, s, horizontal) for v in combo]
end

function transpose(idx::Int, s::Int)::Int
    row, col = coords(idx, s)
    coord_index(col, row, s)
end

function transpose(combo::AbstractArray, s::Int)::AbstractArray
    [transpose(v, s) for v in combo]
end

"""
Determines if `left` is less than `right`--that is, `left` becomes
`right` when the vote distributions are in sorted order.
"""
function voter_dist_lt(left::AbstractArray, right::AbstractArray)
    left_s = sort(left)
    right_s = sort(left)
    for (l, r) in zip(left_s, right_s)
        if l > r
            return false
        elseif l < r
            return true
        end
    end
    false  # exactly equal
end

function combo_duplicated(combo::AbstractArray, s::Int)
    voter_dist_lt(reflect(combo, s, true), s) ||
    voter_dist_lt(reflect(combo, s, false), s) ||
    voter_dist_lt(rot(combo, s, 90), s) ||
    voter_dist_lt(rot(combo, s, 180), s) ||
    voter_dist_lt(rot(combo, s, 270), s) ||
    voter_dist_lt(transpose(combo, s), s) ||
    voter_dist_lt(rot(transpose(combo, s), s, 180), s)
end

"""
Determines the number of unique combinations resulting from
transforming a combination (reflection, rotation, transpose).
"""
function combo_count(combo::AbstractArray)
    combos = Set([
        sort(combos),
        sort(reflect(combo, s, true)),
        sort(reflect(combo, s, false)),
        sort(rot(combo, s, 90)),
        sort(rot(combo, s, 180)),
        sort(rot(combo, s, 270)),
        sort(transpose(combo, s)),
        sort(rot(transpose(combo, s), s, 180))
    ])
    length(combos)
end

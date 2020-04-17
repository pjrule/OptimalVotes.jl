include("./dedupe.jl")
using Test
using Combinatorics 

@testset "Deduplicated vote distributions" begin
    area::Int = 36
    side::Int = 6
    n_voters::Int = 4
    @testset "Rotations" begin
        last_idx = 0
        for row in 1:side
            for col in 1:side
                idx = coord_index(row, col, side)
                @test idx == last_idx + 1  # Indices wrap around
                @test rot(idx, side, 0) == idx
                @test rot(idx, side, 180) == rot(rot(idx, side, 90), side, 90)
                @test rot(idx, side, 270) == rot(rot(idx, side, 90), side, 180)
                @test rot(rot(idx, side, 180), side, 180) == idx
                @test rot(rot(idx, side, 270), side, 90) == idx
                @test_throws DomainError rot(idx, side, 80)
                last_idx = idx
            end
        end
    end

    @testset "Transpose" begin
        for row in 1:side
            for col in 1:side
                idx = coord_index(row, col, side)
                t_row, t_col = coords(transpose(idx, side), side)
                @test t_row == col && t_col == row
                @test transpose(transpose(idx, side), side) == idx
            end
        end
    end

    @testset "Reflections" begin
        for row in 1:side
            for col in 1:side
                idx = coord_index(row, col, side)
                horiz_idx = reflect(idx, side, true)
                vert_idx = reflect(idx, side, false)
                horiz_row, horiz_col = coords(horiz_idx, side)
                vert_row, vert_col = coords(vert_idx, side)
                @test horiz_row == row && horiz_col == side + 1 - col
                @test vert_row == side + 1 - row && vert_col == col
                @test reflect(horiz_idx, side, true) == idx
                @test reflect(vert_idx, side, false) == idx
            end
        end
    end

    @testset "Enumeration of vote distributions" begin
        # We dedupe the vote distributions (that is, we remove vote distributions
        # that differ from one we've seen only by orientation) and then rehydrate
        # the deduped vote distributions by applying 90º, 180º, and 270º rotations,
        # the transpose, horizontal and vertical flips, and the transpose of the 180º
        # rotation.
        all_combos = [c for c in combinations(1:area, n_voters)]
        combos_from_deduped = []
        @test length(all_combos) == binomial(area, n_voters)
        for c in all_combos
            if !combo_duplicated(c, minimum(c), side)
                push!(combos_from_deduped, c)
                for angle in (90, 180, 270)
                    push!(combos_from_deduped, sort([rot(v, side, angle) for v in c]))
                end
                push!(combos_from_deduped, sort([reflect(v, side, true) for v in c]))
                push!(combos_from_deduped, sort([reflect(v, side, false) for v in c]))
                push!(combos_from_deduped, sort([transpose(v, side) for v in c]))
                push!(combos_from_deduped, sort([rot(transpose(v, side), side, 180) for v in c]))
            end
        end
        @test Set(all_combos) == Set(combos_from_deduped)
    end
end

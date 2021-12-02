using Test
using Unitful: Quantity
using NucleicAcidFold: Fold, RNA_BPMODEL, exhaustive_mfe, exhaustive_partfn,
    exhaustive_bpp_partfn, exhaustive_design

@testset "exhaustive" begin
    @testset "mfe (bpmodel)" begin
        seq = "GGGAAACCC"
        model = RNA_BPMODEL
        @test exhaustive_mfe(Fold(seq, model)) == (-9.0u"kcal/mol", Pairtable("(((...)))"))
        # compare exhaustive mfe for random seq to dyn prog solution
        for _ = 1:3
            seq = randseq(13)
            fold = Fold(seq, model)
            en_mfe = mfe(fold)
            en_mfe_ex, _ = exhaustive_mfe(fold)
            @test en_mfe == en_mfe_ex
        end
    end
    @testset "partfn (bpmodel)" begin
        model = RNA_BPMODEL
        seq = "GGGAAACCC"
        for T in (Float64, BigFloat, LogSR{Float64})
            fold = Fold(seq, model)
            @test exhaustive_partfn(T, fold) isa T
            @test exhaustive_partfn(fold) isa Quantity
        end

        for seq in ["UUUCGAAGUUAGUCA", "CGUGGUCCUCUCCGU"]
            fold = Fold(seq, model)
            RTlogQ = model.RT * log(exhaustive_partfn(Float64, fold))
            @test -RTlogQ ≈ partfn(fold)
            @test exhaustive_partfn(fold) ≈ partfn(fold)
        end
    end

    @testset "bpp_partfn (bpmodel)" begin
        seq = "GGGAAACCC"
        model = RNA_BPMODEL
        T = BigFloat
        n = length(seq)
        fold = Fold(seq, model)
        mRTlogQ, p = exhaustive_bpp_partfn(fold)
        @test mRTlogQ isa Quantity
        @test p isa Matrix
        @test size(p) == (n, n)
        @test all(x -> 0.0 <= x <= 1.0, p)
        @test mRTlogQ ≈ partfn(fold)
    end

    @testset "design (bpmodel)" begin
        model = RNA_BPMODEL
        dbn = "(...)"
        n = length(dbn)
        pt = Pairtable(dbn)
        res = exhaustive_design(pt, model)
        @test res isa Vector{Pair{String,Float64}}
        res = exhaustive_design(dbn, model)
        @test res isa Vector{Pair{String,Float64}}
        @test length(res) > 0
        for (s, p) in res
            @test length(s) == n
            @test 0.0 <= p <= 1.0
        end
    end
end

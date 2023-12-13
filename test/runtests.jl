using LengthFreeStaticMatrices, StaticArrays, Aqua, Test

t = (1, 2, 3, 4, 5, 6)
x = LSMatrix{3,2,Int}(t)

Aqua.test_all(LengthFreeStaticMatrices)

@testset "All tests" begin
    @testset "Internals" begin
        import LengthFreeStaticMatrices: nest_tuple
        import StaticArrays: Size
        t = NTuple{6}(1:6)
        @test nest_tuple(Float64, t, Size(6)) === NTuple{6,Float64}(1:6)
        @test nest_tuple(Float64, t, Size(3,2)) === ((1.0, 2.0, 3.0), (4.0, 5.0, 6.0))
        @test nest_tuple(t, Size(6)) === NTuple{6}(1:6)
        @test nest_tuple(t, Size(3,2)) === ((1, 2, 3), (4, 5, 6))
    end
    @testset "Constructors and conversion" begin
        @test LSMatrix{3,2}(t) === x
        @test LSMatrix{3,2}(1, 2, 3, 4, 5, 6) === x
        @test LSMatrix{3,2}([1 4; 2 5; 3 6]) === x
        @test Tuple(x) === t
        @test convert(LSMatrix{3,2}, t) === x
        @test x == [1 4; 2 5; 3 6]
        @test x == SMatrix(x)
        @test x == MMatrix(x)
        @test similar_type(x, Float64) <: LSMatrix{3,2,Float64}
        @test similar_type(x, Int, Size(2)) <: SVector{2,Int}
        @test similar_type(x, Int, Size(3,4)) <: LSMatrix{3,4,Int}
        @test similar_type(x, Int, Size(5,6,7)) <: SArray{Tuple{5,6,7},Int}
    end
    @testset "Indexing" begin
        @test CartesianIndices(x) == CartesianIndices((1:3, 1:2))
        @test all(x[n] == n for n in 1:6)
        @test all(x[n] == LinearIndices(x)[n] for n in CartesianIndices(x))
        @test_throws BoundsError x[4,1]
        @test_throws BoundsError x[1,4]
    end
    @testset "Views and slices" begin
        @test view(x, :, :) === x
        @test view(x, 1, :) === x[1,:]
        @test view(x, :, 1) === x[:,1]
        @test view(x, 1, 1)[] === x[1,1]
        @test eachcol(x) == eachcol(SMatrix(x))
        @test eachrow(x) == eachrow(SMatrix(x))
    end
    @testset "Other functions" begin
        @test zero(LSMatrix{3,3,Int}) == zero(SMatrix{3,3,Int})
        @test one(LSMatrix{3,3,Int}) == one(SMatrix{3,3,Int})
    end
end

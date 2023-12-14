# LengthFreeStaticMatrices.jl

Have you ever wanted to include a `SMatrix` as a field for a struct, but realized that you need to
include a separate length parameter in order to create a pure bits type?
```julia
julia> using StaticArrays

julia> struct Test{M,N,T}
           matrix::SMatrix{M,N,T}
       end

julia> isbitstype(Test{2,3,Int})
false

julia> struct AnotherTest{M,N,T,L}
           matrix::SMatrix{M,N,T,L}
       end

julia> isbitstype(AnotherTest{2,3,Int,6})
true
```
This package solves this problem by introducing a new type, `LSMatrix{M,N,T}`, which stores its data
in an `NTuple{M,NTuple{N,T}}`. We also provide the alias `SquareLSMatrix{D,T}` for square matrices.
```julia
julia> struct YetAnotherTest{M,N,T}
           matrix::LSMatrix{M,N,T}
       end

julia> isbitstype(YetAnotherTest{2,3,Int})
true
```

## Acknowledgements

This functionality was originally implemented by [Thomas Christensen](https://github.com/thchr/) for
the [Crystalline.jl](https://github.com/thchr/Crystalline.jl) package for square matrices.
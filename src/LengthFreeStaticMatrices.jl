module LengthFreeStaticMatrices

using StaticArraysCore
import StaticArraysCore: StaticArray, StaticMatrix, SArray, SMatrix, Size, similar_type

import Base: @propagate_inbounds

#---Helper functions-------------------------------------------------------------------------------#
"""
    LengthFreeStaticMatrices.nest_tuple([::Type{T} = eltype(t)], t::Tuple, ::Size{S})

Converts a flat tuple `t` into nested tuples `NTuple{S[1],NTuple{S[2],...}}` to arbitrary depth.
"""
function nest_tuple(::Type{T}, t::Tuple, ::Size{S}) where {T,S}
    @assert length(t) === prod(S) string(
        "Input tuple must have length ", prod(S), " (got length ", length(t), ")."
    )
    # Specialized implementation for matrices should solve type inference problem
    if length(S) === 1
        return NTuple{only(S),T}(t)
    elseif length(S) === 2
        (M,N) = S
        return ntuple(i -> NTuple{M,T}(t[(M * (i-1)) .+ (1:M)]), Val{N}())
    end
    # This generic implementation is type unstable
    # Probably best to implement it as a generated function
    return ntuple(last(S)) do i
        SS = S[1:end-1]
        index_range = S[end-1]*(i-1) .+ (1:prod(SS))
        return nest_tuple(T, t[index_range], Size(SS))
    end
end

nest_tuple(t::Tuple, sz::Size) = nest_tuple(eltype(t), t, sz)

#---LSMatrix defintion-----------------------------------------------------------------------------#
"""
    LSMatrix{M,N,T} <: StaticArraysCore.StaticMatrix{M,N,T}

A data structure with equivalent behavior to `StaticArraysCore.SMatrix{D,D,T,L}`, but lacking the 
`L` type parameter representing the length of the underlying tuple. This is accomplished by storing 
the matrix coefficients as a `NTuple{N,NTuple{M,T}}`.
"""
struct LSMatrix{M,N,T} <: StaticMatrix{M,N,T}
    data::NTuple{N,NTuple{M,T}}
    LSMatrix{M,N,T}(t::Tuple) where {M,N,T} = new(nest_tuple(T, t, Size(M,N)))
end

"""
    SquareLSMatrix{D,T} (alias for LSMatrix{D,D,T})

A data structure with equivalent behavior to `StaticArraysCore.SMatrix{D,D,T,L}`, but lacking the 
`L` type parameter representing the length of the underlying tuple. This is accomplished by storing 
the matrix coefficients as a `NTuple{D,NTuple{D,T}}`.
"""
const SquareLSMatrix{D,T} = LSMatrix{D,D,T}

#---StaticArrays API implementation----------------------------------------------------------------#

# Define the implementation with Cartesian indices first for bounds checking
# Linear indexing converts the input to Cartesian indices
# TODO: should we define IndexStyle() for this type as IndexCartesian()?
@propagate_inbounds function Base.getindex(x::LSMatrix, a::Int, b::Int)
    @boundscheck all(in.((a,b), axes(x))) || throw(BoundsError(x, (a,b)))
    return x.data[b][a]
end

@propagate_inbounds Base.getindex(x::LSMatrix, i::Int) = x[reverse(divrem(i-1, size(x,1)) .+ 1)...]

Base.Tuple(x::LSMatrix) = NTuple{length(x)}(Iterators.flatten(x.data))

# For arrays that are not matrices, just construct an SArray of the appropriate size
# TODO: any reason to prefer that the similar type in the 2D case is SMatrix?
function similar_type(::Type{M}, ::Type{T}, ::Size{S}) where {M<:LSMatrix,T,S}
    length(S) == 2 && return LSMatrix{S[1],S[2],T}
    return SArray{Tuple{S...},T,length(S),prod(S)}
end

#---Construction and conversion--------------------------------------------------------------------#

LSMatrix{M,N}(t::Tuple) where {M,N} = LSMatrix{M,N,promote_type(typeof.(t)...)}(t)

#---SMatrix-like behavior not implemented by StaticMatrix------------------------------------------#

# This ensures that eachrow() and eachcol() return similar objects to those produced with an SMatrix
# TODO: SOneTo indices are excluded due to their absence in StaticArraysCore
#       Add this back in, probably through a weakdep
function Base.view(
    x::LSMatrix,
    i::Union{Colon, Integer, StaticArray{<:Tuple, Int}, CartesianIndex}...
) 
    v = x[i...]
    # Views of a single element of an SMatrix should be a StaticArrays.Scalar (SArray{Tuple{}})
    return v isa eltype(x) ? SArray{Tuple{}}(v) : v
end

#---Exports----------------------------------------------------------------------------------------#
export LSMatrix, SquareLSMatrix

end # module

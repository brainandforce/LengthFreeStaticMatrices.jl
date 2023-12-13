module LengthFreeStaticMatrices

using StaticArraysCore
import StaticArraysCore: StaticArray, StaticMatrix, SArray, SMatrix, Size, similar_type

import Base: @propagate_inbounds

#---Helper functions-------------------------------------------------------------------------------#
"""
    LengthFreeStaticMatrices.nest_tuple([::Type{T} = eltype(T)], t::Tuple, ::Size{S})

Converts a flat tuple `t` into nested tuples `NTuple{S[1],NTuple{S[2],...}}`.
"""
function nest_tuple(::Type{T}, t::Tuple, ::Size{S}) where {T,S}
    @assert length(t) ===  prod(S) string(
        "Input tuple must have length ", prod(S), " (got length ", length(t), ")."
    )
    isone(length(S)) && return NTuple{only(S),T}(t)
    return ntuple(last(S)) do i
        SS = S[1:end-1]
        index_range = S[end-1]*(i-1) .+ (1:prod(SS))
        return nest_tuple(T, t[index_range], Size(SS))
    end
end

nest_tuple(t::Tuple, sz::Size) = nest_tuple(eltype(t), t, sz)

#---LSMatrix defintion-----------------------------------------------------------------------------#
"""
    LSMatrix{M,N,T} <: StaticMatrix{M,N,T}

Equivalent to `SMatrix{M,N,T,L}`, but without the type parameter `L` representing the length.
"""
struct LSMatrix{M,N,T} <: StaticMatrix{M,N,T}
    data::NTuple{N,NTuple{M,T}}
    LSMatrix{M,N,T}(t::Tuple) where {M,N,T} = new(nest_tuple(T, t, Size(M,N)))
end

const SqSMatrix{D,T} = LSMatrix{D,D,T}

#---StaticArrays API implementation----------------------------------------------------------------#

@propagate_inbounds function Base.getindex(x::LSMatrix, a::Int, b::Int)
    @boundscheck all(in.((a,b), axes(x))) || throw(BoundsError(x, (a,b)))
    return x.data[b][a]
end

@propagate_inbounds Base.getindex(x::LSMatrix, i::Int) = x[reverse(divrem(i-1, size(x,1)) .+ 1)...]

Base.Tuple(x::LSMatrix) = NTuple{length(x)}(Iterators.flatten(x.data))

function similar_type(::Type{M}, ::Type{T}, ::Size{S}) where {M<:LSMatrix,T,S}
    length(S) == 2 && return LSMatrix{S[1],S[2],T}
    return SArray{Tuple{S...},T,length(S),prod(S)}
end

#---Construction and conversion--------------------------------------------------------------------#

LSMatrix{M,N}(t::Tuple) where {M,N} = LSMatrix{M,N,promote_type(typeof.(t)...)}(t)

#---Views------------------------------------------------------------------------------------------#
# TODO: if StaticArrays is loaded, add SOneTo to this union
function Base.view(
    x::LSMatrix,
    i::Union{Colon, Integer, StaticArray{<:Tuple, Int}, CartesianIndex}...
) 
    v = x[i...]
    return v isa eltype(x) ? SArray{Tuple{}}(v) : v
end

#---Exports----------------------------------------------------------------------------------------#
export LSMatrix, SqSMatrix

end # module ParameterlessStaticMatrices

struct MaxMinBloomFilter{T}
    min::T
    max::T
end

MaxMinBloomFilter(x::MaxMinBloomFilter) = x
MaxMinBloomFilter(x::T) where {T} = MaxMinBloomFilter{T}(x,x)
function Base.in(item::T,mmbf::MaxMinBloomFilter{T}) where {T}
    mmbf.min <= item <= mmbf.max
end
function insert(bf::MaxMinBloomFilter{T},x::T) where {T} 
    MaxMinBloomFilter{T}(min(bf.min,x),max(bf.max,x))
end
function insert(bf::MaxMinBloomFilter{T},x::MaxMinBloomFilter{T}) where {T} 
    MaxMinBloomFilter{T}(min(bf.min,x.min),max(bf.max,x.max))
end


Base.show(io::IO, bf::MaxMinBloomFilter) = print("[$(bf.min)..$(bf.max)]")

bloom_table_type(t::Type{<:AbstractVector{T}}) where {T} = Vector{MaxMinBloomFilter{T}}
bloom_table_type(t::Type{Vector{MaxMinBloomFilter{T}}}) where {T} = Vector{MaxMinBloomFilter{T}}
function make_bloom_table(v::AbstractVector{T},fanout) where {T}
    bv = bloom_table_type(Vector{T})(undef,cld(length(v),fanout))
    for (i,b) in enumerate(v)
        if isone(i % fanout)
            bv[cld(i,fanout)] = MaxMinBloomFilter(b)
        end
        bv[cld(i,fanout)] = insert(bv[cld(i,fanout)],b)
    end
    bv
end

struct HiVecSet{N,F,T,V<:AbstractVector{T}}
    table::V
    bloomtables::NTuple{N,Vector{MaxMinBloomFilter{T}}}
end

const HiBitSet{N,F} = HiVecSet{N,F,Bool,BitVector}

function HiVecSet{N,F}(v::V) where {N,F,T,V<:AbstractVector{T}} 
    mxn = v
    bloom_table_iter = ((mxn = make_bloom_table(mxn,F);mxn) for i in 1:N)
    HiVecSet{N,F,T,V}(v, Tuple(bloom_table_iter))
end

HiVecSet{N,F,T,V}(v::V) where {N,F,T,V<:AbstractVector{T}} = HiVecSet{N,F}(v)

Base.getindex(bv::HiVecSet,i) = bv.table[i]
hbs_layer(l, hbs::HiVecSet) = hbs.bloomtables[l]
Base.firstindex(hbs::HiVecSet) = firstindex(hbs.table)
Base.lastindex(hbs::HiVecSet) = lastindex(hbs.table)
Base.length(hbs::HiVecSet) = length(hbs.table)

layerget(l,hbs::HiVecSet,i) = hbs_layer(l,hbs)[i]
layerget_zero(l,hbs::HiVecSet,i) = hbs_layer(l,hbs)[begin + i]

function repair_invariant(v::HiVecSet{N,F,T},n) where {N,F,T}
    n -= 1
    n -= n % F
    chunk = view(v.table,(n+1):min(n+F,length(v)))
    mxn = MaxMinBloomFilter(first(chunk))
    for e in chunk
        mxn = insert(mxn,e)
    end
    for l = 1:N
        n = div(n,F)
        maxmins = hbs_layer(l,v)
        maxmins[begin+n] = mxn
        chunkmaxmins = view(maxmins,(n+1):min(n+F,length(maxmins)))
        for e in chunkmaxmins
            mxn = insert(mxn,e)
        end
    end
end

function Base.setindex!(v::HiVecSet,value,i)
    v.table[i] = value
    repair_invariant(v,i)
end

function Base.push!(v::HiVecSet,value)
    push!(v.table,value)
    repair_invariant(v,length(v.table))
end

function Base.show(io::IO,v::HiVecSet{N,F,T}) where {N,F,T}
    println("HiVecSet{$N,$F,$T} with $(length(v)) elements:")
    for i in 1:length(v)
        print(io,"$(v[i]) \t | ")
        j = i - 1
        for l in 1:N
            print(io,"\t")
            if j % F^l == 0
                print(io, layerget_zero(l,v,div(j,F^l)))
            elseif (j+1) % F^l != 0 
                i == length(v) ? print(io,"[ ↓↓ ]\t") : print(io,"[ || ]\t")
            else
                print(io,"[<++ ]\t")
            end
        end
        println(io,";")
    end
end



# Interface: getindex returns booleans, 
# layerget gets the Or of all booleans returned, much like for hibitset.
abstract type HBSQuery{N,F} end

function Base.findnext(q::HBSQuery{N,F},i::Integer) where {N,F}
    i -= firstindex(q) # This algorithm uses zero-indexing for modular arithmetic.
    lastind = lastindex(q) - firstindex(q)
    while i <= lastind
        if q[begin+i] 
            return firstindex(q) + i 
        end
        step = 1
        l = 1
        j = i
        while l<=N && iszero(j % F) && !layerget_zero(l,q,div(j,F))
            l+=1
            j = div(j,F)
            step *= F
        end
        i += step
    end
end

function Base.iterate(q::HBSQuery,state=firstindex(q))
    n = findnext(q,state)
    isnothing(n) ? nothing : (n,n+1)
end
Base.eltype(::Type{<:HBSQuery}) = Int
Base.IteratorSize(::Type{<:HBSQuery}) = Base.SizeUnknown()

import Base.(!)

struct EqualsQuery{N,F,T,V} <: HBSQuery{N,F}
    element::T
    hvs::V
end
equalsquery(hvs::HiVecSet{N,F,T,V},value::T) where {N,F,T,V} = EqualsQuery{N,F,T,HiVecSet{N,F,T,V}}(value,hvs)

Base.firstindex(q::EqualsQuery) = firstindex(q.hvs)
Base.lastindex(q::EqualsQuery) = lastindex(q.hvs)
Base.getindex(q::EqualsQuery,i) = q.hvs[i] == q.element
layerget(l,q::EqualsQuery,i) = iszero(l) ? q[i] : q.element ∈ layerget(l,q.hvs,i)
layerget_zero(l,q::EqualsQuery,i) = iszero(l) ? q[begin+i] : q.element ∈ layerget_zero(l,q.hvs,i)

!(q::EqualsQuery{N,F,Bool,V}) where {N,F,V} = EqualsQuery{N,F,Bool,V}(!q.element,q.hvs)


import Base.(&)

struct AndQuery{N,F,A<:HBSQuery{N,F},B<:HBSQuery{N,F}} <: HBSQuery{N,F}
    a::A
    b::B
end

(a::A & b::B) where {N,F,A<:HBSQuery{N,F},B<:HBSQuery{N,F}} = AndQuery(a,b)

Base.firstindex(q::AndQuery) = firstindex(q.a)
Base.lastindex(q::AndQuery) = lastindex(q.a)
Base.getindex(q::AndQuery,i) = q.a[i] & q.b[i]
layerget(l,q::AndQuery,i) = layerget(l,q.a,i) & layerget(l,q.a,i)
layerget_zero(l,q::AndQuery,i) = layerget_zero(l,q.a,i) & layerget_zero(l,q.a,i)

!(q::AndQuery) = !q.a | !q.b

import Base.(|)

struct OrQuery{N,F,A<:HBSQuery{N,F},B<:HBSQuery{N,F}} <: HBSQuery{N,F}
    a::A
    b::B
end

(a::A | b::B) where {N,F,A<:HBSQuery{N,F},B<:HBSQuery{N,F}} = OrQuery(a,b)

Base.firstindex(q::OrQuery) = firstindex(q.a)
Base.lastindex(q::OrQuery) = lastindex(q.a)
Base.getindex(q::OrQuery,i) = q.a[i] | q.b[i]
layerget(l,q::OrQuery,i) = layerget(l,q.a,i) | layerget(l,q.a,i)
layerget_zero(l,q::OrQuery,i) = layerget_zero(l,q.a,i) | layerget_zero(l,q.a,i)

!(q::OrQuery) = !q.a & !q.b



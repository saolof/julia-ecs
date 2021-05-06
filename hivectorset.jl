struct MaxMinBloomFilter{T}
    min::T
    max::T
end

struct HiVecSet{N,F,T}
    table::Vector{T}
    bloomtables::NTuple{N,Vector{MaxMinBloomFilter{T}}}
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

bloom_table_type(t::Type{Vector{T}}) where {T} = Vector{MaxMinBloomFilter{T}}
bloom_table_type(t::Type{Vector{MaxMinBloomFilter{T}}}) where {T} = Vector{MaxMinBloomFilter{T}}
function make_bloom_table(v::Vector{T},fanout) where {T}
    bv = bloom_table_type(Vector{T})(undef,cld(length(v),fanout))
    for (i,b) in enumerate(v)
        if isone(i % fanout)
            bv[cld(i,fanout)] = MaxMinBloomFilter(b)
        end
        bv[cld(i,fanout)] = insert(bv[cld(i,fanout)],b)
    end
    bv
end

function HiVecSet{N,F}(v::Vector{T}) where {N,F,T} 
    mxn = v
    bloom_table_iter = ((mxn = make_bloom_table(mxn,F);mxn) for i in 1:N)
    HiVecSet{N,F,T}(v, Tuple(bloom_table_iter))
end

Base.getindex(bv::HiVecSet,i) = bv.table[i]
hbs_layer(l, hbs::HiVecSet) = hbs.bloomtables[l]
Base.length(hbs::HiVecSet) = length(hbs.table)

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

function Base.show(io::IO,v::HiVecSet{N,F,T}) where {N,F,T}
    println("HiVecSet{$N,$F,$T} with $(length(v)) elements:")
    for i in 1:length(v)
        print(io,"$(v[i]) | ")
        j = i - 1
        for l in 1:N
            print(io,"\t")
            if j % F^l == 0
                print(io,hbs_layer(l,v)[begin + div(j,F^l)])
            elseif (j+1) % F^l != 0 
                i == length(v) ? print(io,"[ ↓↓ ]") : print(io,"[ || ]")
            else
                print(io,"[<++ ]")
            end
        end
        println(io,";")
    end
end


function findnext_equals(x::T,hbs::HiVecSet{N,F,T},n) where {N,F,T}
    m = min(cld(n-1,F)*F,length(hbs))
    r = findnext(bf -> in(x,bf),view(hbs.table,n:m),1)
    if !isnothing(r) || m==length(hbs)
        return n + r - 1
    end
    n = m  # n is zero indexed here.
    l = 1
    i = div(n,F)
    while l <= N && !in(x,hbs_layer(l,hbs)[begin + i])
        layer = hbs_layer(l,hbs)
        m = min(cld(i,F)*F,length(layer))
        r = findnext(bf -> in(x,bf),view(layer,(i+1):m),1)
        if isnothing(r)
            if m == length(layer)
                return
            end
            println("Rose to layer $l , n set to $(m+1), was $(n+1)")        
            l+= 1
            n = m
            i = div(n,F)
        else
            print("Rose to layer $l , n was $(n+1), ")
            n = i + r - 1
            println("set to $(n+1)")
            l+=1
            break
        end
    end
    l -=1
    n += 1 # Back to 1-indexing.
    while l >= 1
        n = findnext(bf -> in(x,bf),hbs_layer(l,hbs),n)
        if isnothing(n) return end
        n = (n-1)*F + 1 
        l -= 1
        println("fell to layer $l, n set to $n)")
    end
    findnext(y->x==y,hbs.table,n)
end

struct IterEquals{N,F,T}
    x::T
    hbs::HiVecSet{N,F,T}
end
eltype(::Type{IterEquals{N,F,T}}) where {N,F,T} = Int
Base.IteratorSize(::Type{<:IterEquals}) = Base.SizeUnknown() 
iterequals(x::T,hbs::HiVecSet{N,F,T}) where {N,F,T} = IterEquals{N,F,T}(x,hbs)

function Base.iterate(ie::IterEquals{N,F,T},state=1) where {N,F,T} 
    index = findnext_equals(ie.x,ie.hbs,state)
    if isnothing(index)
        return
    else
        return (index,index+1)
    end
end



a = HiVecSet{4,4}([5 for i in 1:255]);
a[20] = 3;
a[21] = 3;
a[25] = 3;
a[27] = 3;
a[180] = 3;
a[190] = 3;

collect(iterequals(3,a))



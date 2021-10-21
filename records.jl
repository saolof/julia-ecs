using SimpleTraits

import Base.(<)


struct Remove end


function sorted_keys(::Type{NamedTuple{names,types}}) where {names, types}  
    ns = sort!([name for name in names if fieldtype(NamedTuple{names,types},name) != Remove]; by=String)
    return (ns...,)
end
function sort_by_keys(nt::NamedTuple{names}) where {names} 
    ns = sorted_keys(typeof(nt))
    NamedTuple{ns}(nt)
end
function sorted_types(sortednames,T::Type{NamedTuple{names,types}}) where {names,types}
    Tuple{Any[fieldtype(T,sortednames[i]) for i in 1:length(sortednames)]...}
end


struct Record{names,types}
    tuple::NamedTuple{names,types}

    function Record(ntuple::T) where {T<:NamedTuple}
        names = sorted_keys(T)
        types = sorted_types(names,T)
        new{names,types}((sort_by_keys(ntuple)))
    end
end

function Record(r::Record;kwargs...)
    Record(merge(Tuple(r),kwargs))
end

tuple_field(rec::Record) = getfield(rec,:tuple)


function show_with_curlies(io::IO, t::NamedTuple)
    n = nfields(t)
    for i = 1:n
        # if field types aren't concrete, show full type
        if typeof(getfield(t, i)) !== fieldtype(typeof(t), i)
            show(io, typeof(t))
            print(io, "r{")
            show(io, Tuple(t))
            print(io, "}")
            return
        end
    end
    if n == 0
        print(io, "NamedTuple()")
    else
        typeinfo = get(io, :typeinfo, Any)
        print(io, "r{")
        for i = 1:n
            print(io, fieldname(typeof(t),i), " = ")
            show(IOContext(io, :typeinfo =>
                           t isa typeinfo <: NamedTuple ? fieldtype(typeinfo, i) : Any),
                 getfield(t, i))
            if n == 1
                print(io, ",")
            elseif i < n
                print(io, ", ")
            end
        end
        print(io, "}")
    end
end

function Base.show(io::IO,r::Record) 
    show_with_curlies(io,tuple_field(r))
end

Base.getproperty(rec::Record,name::Symbol) = getproperty(getfield(rec,:tuple),name) 

Base.getindex(rec::Record,i) = getindex(tuple_field(rec),i) 
Base.firstindex(rec::Record) = 1
Base.lastindex(rec::Record) = nfields(tuple_field(rec))
Base.length(rec::Record) = length(tuple_field(rec))
Base.iterate(rec::Record) = iterate(tuple_field(rec))
Base.iterate(rec::Record,state) = iterate(tuple_field(rec),state)
Base.eltype(::Type{Record{names,types}}) where {names,types} = eltype(NamedTuple{names,types})




(a::Record{n} < b::Record{n}) where {n} = tuple_field(a) < tuple_field(b) 
Base.isless(a::Record{n},b::Record{n}) where {n} = isless(tuple_field(a), tuple_field(b)) 
Base.same_names(::Record{names}...) where {names} = true
Base.same_names(::Record...) = false
Base.keys(rec::Record{names}) where {names} = names
Base.values(rec::Record) = Tuple(tuple_field(rec))
Base.haskey(rec::Record, key::Union{Integer, Symbol}) = haskey(tuple_field(rec), key)
Base.get(rec::Record, key::Union{Integer, Symbol}, default) = get(tuple_field(rec),key,default)
Base.get(f, rec::Record, key::Union{Integer, Symbol}) = haskey(rec, key) ? getfield(rec, key) : f()

# t = (b=1,a=2.0)
# rec = Record(t)


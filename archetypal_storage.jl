struct EntityLocation
    archetype::Int
    index::Int
end

mutable struct ArchetypalStorage
    entity_counter::Int
    entity_table::Vector{EntityLocation}
    archetypal_storage::Vector{Vector}

    archetype_table::Vector{Type}
    archetype_map::Dict{Type,Int}
    component_table::Dict{Symbol,HiBitSet{3,64}}
end
ArchetypalStorage() = ArchetypalStorage(0,EntityLocation[],Vector[],Type[],Dict{Type,Int}(),Dict{Symbol,HiBitSet{3,64}}())

componentnames(x) = fieldnames(x)

function get_archetype(s::ArchetypalStorage,t::Type{T}) where {T}
    get!(s.archetype_map,t) do 
        push!(s.archetype_table,t)
        push!(s.archetypal_storage,T[])
        n = length(s.archetype_table)
        for (fname,c) in s.component_table
            push!(c,false)
        end
        for fname in fieldnames(t)
            c = get!(s.component_table,fname) do 
                HiBitSet{3,64}(falses(n))
            end
            c[n] = true
        end
        n
    end
end

# (Need to determine whether entities should store their identity).
register_uid(entity,uid::Int) = entity

function insert_entity!(storage::ArchetypalStorage,entity::T) where {T}
    storage.entity_counter += 1
    e = register_uid(entity,storage.entity_counter)
    a = get_archetype(storage,typeof(e))
    push!(storage.archetypal_storage[a], e)
    location = EntityLocation(a,length(storage.archetypal_storage[a]))
    push!(storage.entity_table, location)
end

function get_entity(storage::ArchetypalStorage,uid::Int) 
    location = storage.entity_table[uid]
    storage.archetypal_storage[location.archetype][location.index]
end

function set_entity!(storage::ArchetypalStorage,uid::Int,value) 
    location = storage.entity_table[uid]
    storage.archetypal_storage[location.archetype][location.index] = value
end

Base.getindex(storage::ArchetypalStorage,uid::Int) = get_entity(storage,uid)
Base.setindex!(storage::ArchetypalStorage,value,uid::Int) = set_entity!(storage,uid,value)
Base.push!(storage::ArchetypalStorage,entity) = insert_entity!(storage,entity)


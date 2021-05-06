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
end
ArchetypalStorage() = ArchetypalStorage(0,EntityLocation[],Vector[],Type[],Dict{Type,Int}())

function get_archetype(s::ArchetypalStorage,t::Type{T}) where {T}
    get!(s.archetype_map,t) do 
        push!(s.archetype_table,t)
        push!(s.archetypal_storage,T[])
        length(s.archetype_table)
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


a = ArchetypalStorage()
push!(a,10)
# Todo: figure out how to make this a generated closure.
n = 0
archetypes = Type[]
@generated function archetype(t::Type)
    global n
    global archetypes
    n+=1
    push!(archetypes,t)
    :($n)
end

empty_storage(::Type{Type{T}}) where {T} = Vector{T}()


struct EntityLocation
    archetype::Int
    index::Int
end

mutable struct ArchetypalStorage
    entity_counter::Int
    entity_table::Vector{EntityLocation}
    archetypal_storage::Vector{Vector}
end
# n and archetypes should really be elements in this, not globals.
# Need to figure out a way to do generated closures.

function initialize_archetypes(s::ArchetypalStorage)
    global n # TODO: Figure out how to get rid of those pesky globals.
    if length(s.archetypal_storage) >= n
        return
    end
    for i in (length(s.archetypal_storage) + 1):n
        push!(s.archetypal_storage,empty_storage(archetypes[i]))
    end
end
function ArchetypalStorage() 
    s = ArchetypalStorage(0,EntityLocation[],Vector[])
    initialize_archetypes(s)
    s
end

# (Need to determine whether entities should store their identity).
register_uid(entity,uid::Int) = entity

function insert_entity!(storage::ArchetypalStorage,entity::T) where {T}
    storage.entity_counter += 1
    e = register_uid(entity,storage.entity_counter)
    a = archetype(typeof(e))
    initialize_archetypes(storage)
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
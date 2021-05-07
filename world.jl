const Event = Symbol
const ResourceTag = Symbol
const SystemSuperType = Function

# Each different kind of system should have a unique type.
# You may implement those functions on each system to configure it.
resources_used(system::SystemSuperType) = resources_used(typeof(system))

event_trigger(system::SystemSuperType) = event_trigger(typeof(system))
event_trigger(::Type{<:SystemSuperType}) = :loop

struct World
    system_event_table::Dict{Event,Vector{Vector{SystemSuperType}}}
    scheduler_table::Dict{Event,Set{ResourceTag}}
    resources::Dict{ResourceTag,Any}
end

# Systems that use disjoint resources may be scheduled to run in parallel.
function schedule_system(world::World,system::SystemSuperType,event=event_trigger(system))
    schedulerset = get!(world.scheduler_table,event) do Set{ResourceTag}() end
    for r in resources_used(system)
        if r ∈ schedulerset
            empty!(schedulerset)
            push!(world.system_event_table[event],Vector{SystemSuperType}())
            break
        end
    end
    for r in resources_used
        push!(schedulerset,r)
    end
    push!(last(world.system_event_table[event]),system)
end

function process_event_seq(world::World,event::Event)
    for par_systems in world.system_event_table[event]
        for system in par_systems
            system((world.resources[r] for r in resources_used(system) )...)
        end
    end
end
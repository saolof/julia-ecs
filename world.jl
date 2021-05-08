const Event = Symbol
const ResourceTag = Symbol

struct World
    system_event_table::Dict{Event,Vector{Vector{SystemSuperType}}}
    scheduler_table::Dict{Event,Dict{ResourceTag,Int}}
    resources::Dict{ResourceTag,Any}
end

function World() 
    w = World(Dict{Event,Vector{Vector{SystemSuperType}}}(),Dict{Event,Dict{ResourceTag,Int}}(),Dict{ResourceTag,Any}())
    w.resources[:entities] = ArchetypalStorage()
    w.resources[:world] = w
    w.resources[:sleepduration] = 0.1
    w.resources[:end] = false
    w
end

function schedule_system(world::World,system::SystemSuperType)
    for event in event_trigger(system)
        _schedule_system(world,system,event)
    end
end

# Systems that use disjoint resources may be scheduled to run in parallel. Scheduler is greedy with an equal-depth model.
function _schedule_system(world::World,system::SystemSuperType,event::Event)
    schedulerdict = get!(world.scheduler_table,event) do 
        Dict{ResourceTag,Int}() 
    end
    uses_world = false
    index = 1 + foldl(max,(get!(schedulerdict,r,1) for r in resources_used(system));init=1)
    for r in resources_used(system)
        if r == :world
            uses_world = true
        end
        schedulerdict[r] = index
    end
    evtable = get!(world.system_event_table,event) do 
        Vector{Vector{SystemSuperType}}()
    end
    if uses_world
        index = length(evtable) + 1
        for (key,val) in schedulerdict
            schedulerdict[key] = index
        end
    end
    if index <= length(evtable)
        push!(evtable[index],system)
    else
        push!(evtable,SystemSuperType[system])
    end
end

function process_event_seq(world::World,event::Event)
    for par_systems in world.system_event_table[event]
        for system in par_systems
            system((world.resources[r] for r in resources_used(system) )...)
        end
    end
end

function run_seq(world::World)
    process_event_seq(world,:startup)
    while !world.resources[:end]
        sleep(world.resources[:sleepduration])
        process_event_seq(world,:loop)
    end
    process_event_seq(world,:shutdown)
end
using MacroTools

include("hivectorset.jl")
include("archetypal_storage.jl")
include("world.jl")

w = World()

function startup_system(entities)
    push!(entities,(x=1,y=1))
    push!(entities,(x=2,y=-1))
    push!(entities,(x=3,z=1))
    push!(entities,(x=4,))
    push!(entities,(y=1,))
end
event_trigger(::Type{typeof(startup_system)}) = :startup
schedule_system(w,startup_system)

function print_exes(entities)
    cquery_foreach(@CQuery(x & y),entities) do ent
        println("x is $(ent.x), y is $(ent.y)")        
    end
    cquery_foreach(@CQuery(x & !y),entities) do ent
        println("x is $(ent.x)")        
    end
    cquery_foreach(@CQuery(y & !x),entities) do ent
        println("y is $(ent.y)")        
    end
end
schedule_system(w,print_exes)

process_event_seq(w,:startup)
process_event_seq(w,:loop)

# a = ArchetypalStorage()
# push!(a,10)
# push!(a,(x=1,y=1))
# push!(a,(x=1,z=1))
# push!(a,(x=1,))
# push!(a,(y=1,))


# a = HiVecSet{4,4}([5 for i in 1:255]);
# a[20] = 3;
# a[21] = 3;
# a[25] = 3;
# a[27] = 3;
# a[180] = 3;
# a[190] = 3;


# b = HiVecSet{4,4}(falses(255));
# b[20] = true;
# b[21] = true;
# b[25] = true;
# b[27] = true;
# b[180] = true;
# b[190] = true;

# collect(iterequals(true,b))




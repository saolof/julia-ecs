using MacroTools

include("hivectorset.jl")
include("archetypal_storage.jl")


a = ArchetypalStorage()
push!(a,10)
push!(a,(x=1,y=1))
push!(a,(x=1,z=1))
push!(a,(x=1,))
push!(a,(y=1,))


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




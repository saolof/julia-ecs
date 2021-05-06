include("hivectorset.jl")
include("archetypal_storage.jl")


a = ArchetypalStorage()
push!(a,10)
push!(a,(x=1,y=1))
push!(a,(x=1,z=1))
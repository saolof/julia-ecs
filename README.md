# julia-ecs

This is an experimental dynamic Entity-Component-System library written in Julia, and is intended as a pathfinder rather than for production use. Inspired by ECS libraries in the Rust gamedev ecosystem, such as Legion and Plank.

Intended to demonstate the use of Julia's unique features to implement an archetype-based ECS architecture 
(i.e. entity fields are packed in separate arrays for good memory efficiency, and iterating through a small subset of fields with the query DSL is very fast), that does not sacrifice dynamism and allows a program to be modified while it is running. For an excellent overview of how archetype-based ECS pack components into arrays, see this blog post: https://ajmmertens.medium.com/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9

The queries are compiled on-the-fly to very efficient code thanks to julia's JIT compiler, yet the system is also extensible and allows new archetypes to be created on the fly.
Due to the expressiveness of Julia's type system and zero-cost abstractions, the code is fully dynamic and there is no code size penalty compared to a bitset-based ECS implementation and the core is very small, 
in stark contrast to the traditional situation in systems programming languages where archetypal ECS makes the system substantially trickier to implement and enables dynamic addition
of features while the program is still running. 

Entities in this system present an extensible-record like interface, and can be accessed much like a named tuple despite their exploded memory layout. 
Fields can be added to and removed from an object on the fly.

Also includes a fairly simple scheduler for parallel execution of systems registered to any given signal. The scheduler also allows for dynamic registration of systems.

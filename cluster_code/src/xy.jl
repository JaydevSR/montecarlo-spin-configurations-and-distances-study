"""
    xywolff_step!(N::Int64, spins::Matrix, T::Float64)

Perform one step of Wolff algorithm for XY model (lattice `spins` of size `(N, N)` at temperature `T`).
"""
function xywolff_step!(N::Int, spins::Matrix, T::Float64)
    seed = rand(1:N, 2)  # seed spin position
    u_flip = rand()  # Random unit vector in xy plane
    nbrs = [[1, 0], [N - 1, 0], [0, 1], [0, N - 1]]
    xywolff_cluster_update!(N, spins, seed, u_flip, T, nbrs)
end

"""
    xywolff_cluster_update!(spins::Matrix, seed::AbstractArray, u_flip::Float64, T::Float64)

Build a cluster among `spins` starting at `seed` at temperature `T`. Flip the cluster w.r.t angle `u_flip`.
"""
function xywolff_cluster_update!(N, spins::Matrix, seed::AbstractArray, u_flip::Float64, T::Float64, nbrs)
    stack = []
    sizehint!(stack, N*N)
    push!(stack, seed)
    cluster = falses(size(spins))
    @inbounds sval = spins[seed...]
    @inbounds cluster[seed...] = true
    while !isempty(stack)
        k = pop!(stack)
        @inbounds kval = spins[k...]
        xywolff_flip_spin!(spins, k, u_flip)
        for δ ∈ nbrs
            nn = k + δ
            @. nn = mod1(nn, N)  # Apply periodic boundary conditions
            @inbounds nnval = spins[nn...]
            if !cluster[nn...] && rand() < xywolff_Padd(u_flip, nnval, kval, T)
                push!(stack, nn)
                @inbounds cluster[nn...] = true
            end
        end
    end
end

"""
    xywolff_flip_spin!(spins::Matrix, pos::AbstractArray, u_flip::Float64)

Flip the spin at position `pos` inside lattice `spins` w.r.t. angle `u_flip`.
"""
function xywolff_flip_spin!(spins::Matrix, pos::AbstractArray, u_flip::Float64)
    old = spins[pos...]
    new = 0.5 + 2 * u_flip - old  # flipping w.r.t vector with angle ϕ: θ --> π + 2ϕ - θ
    new = mod(new + 1, 1)
    spins[pos...] = new
    return old, spins[pos...]
end

"""
    xywolff_Padd(u_flip::Float64, s1::Float64, s2::Float64, T::Float64; J=1)

Calculate the probability of adding spin `s2` to cluster of as a neighbour of `s1` at temperature `T` w.r.t angle `u_flip`. The interaction energy defaults to `1`.
"""
function xywolff_Padd(u_flip::Float64, s1::Float64, s2::Float64, T::Float64; J=1)
    arg = -2 * J * cos2pi(u_flip - s1) * cos2pi(u_flip - s2) / T
    return 1 - exp(arg)
end

function cos2pi(x::Float64)
    return cos(2 * pi * x)
end

function sin2pi(x::Float64)
    return sin(2 * pi * x)
end

function xy_spindot(s1, s2)
    return cos2pi(s1-s2)
end
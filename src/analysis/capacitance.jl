function capacitance(df, I)
    t, V = df[!, Symbol("Time (s)")], df[!, Symbol("Potential (V)")]
    idxs = findall(v->v > 0, V)
    t, V = t[idxs], V[idxs]

    ∫Vdt = integrate(t, V)
    # ΔV = -(reverse(extrema(V))...)
    ΔV = 1.4

    return 2*I*∫Vdt/ΔV^2
end

function dynamic_capacitance(df, I)
    t, V = df[!, Symbol("Time (s)")], df[!, Symbol("Potential (V)")]
    idxs = findall(v->v > 0, V)
    t, V = t[idxs], V[idxs]

    ts = range(extrema(t)..., length=50)
    itp = LinearInterpolation(t, V)

    tg = only.(Interpolations.gradient.(Ref(itp), ts))
    C = I ./ tg
    return itp.(ts), C
end

function add_capacitance!(Cs, datafile, df)
    I = parse(Float64, filevalue(datafile))
    C = capacitance(df, I)

    push!(Cs[!, :Porosity], foldervalue(datafile))
    push!(Cs[!, :I], I)
    push!(Cs[!, :C], C)
end

function add_dyn_capacitance!(dyn_Cs, datafile, df)
    I = parse(Float64, filevalue(datafile))
    V, Cs = dynamic_capacitance(df, I)

    append!(dyn_Cs[!, :Porosity], repeat([foldervalue(datafile)], length(V)))
    append!(dyn_Cs[!, :I], repeat([I], length(V)))
    append!(dyn_Cs[!, :V], V)
    append!(dyn_Cs[!, :C], Cs)
end

function capacitance(df, I)
    t, V = df[!, Symbol("Time (s)")], df[!, Symbol("Potential (V)")]
    idxs = findall(v->v > 0, V)
    t, V = t[idxs], V[idxs]

    ∫Vdt = integrate(t, V)
    ΔV = -(reverse(extrema(V))...)

    return 2*I*∫Vdt/ΔV^2
end

function add_capacitance!(capacitances, datafile, df)
    I = parse(Float64, filevalue(datafile))
    C = capacitance(df, I)

    push!(capacitances[!, :folder], foldervalue(datafile))
    push!(capacitances[!, :I], I)
    push!(capacitances[!, :C], C)
end

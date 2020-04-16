function capacitance(df, I)
    t, V = df[!, Symbol("Time (s)")], df[!, Symbol("Potential (V)")]
    idxs = findall(v->v > 0, V)
    t, V = t[idxs], V[idxs]

    ∫Vdt = integrate(t, V) * u"V*s"
    # ΔV = -(reverse(extrema(V))...)
    ΔV = 1.4u"V"

    return ∫Vdt, 2*I*∫Vdt/ΔV^2
end

function specific_capacitance(C, porosity, folder)
    A = 71u"cm^2"
    a = (1.2*1.8)u"cm^2"

    df = CSV.read("$folder/weights.csv")
    mass = (df[!,:after].*u"g" .- df[!,:before].*u"g") .* a ./ A .|> u"μg"
    mass_dict = Dict([10,30,50,70,90,110].=>mass[1:6])

    C / mass_dict[porosity]
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

function add_capacitance!(Cs, datafile, df, folder)
    I = parse(Float64, filevalue(datafile)) * u"A"
    porosity = parse(Int, foldervalue(datafile))
    ∫Vdt, C_abs = capacitance(df, I)
    C = specific_capacitance(C_abs, porosity, folder)

    push!(Cs[!, :Area], ustrip(u"V*s", ∫Vdt))
    push!(Cs[!, :I], ustrip(u"mA", I))
    push!(Cs[!, :C_abs], ustrip(u"μF", C_abs))
    push!(Cs[!, :C], ustrip(u"F/g", C))

    return nothing
end

function add_dyn_capacitance!(dyn_Cs, datafile, df)
    I = parse(Float64, filevalue(datafile))
    V, Cs = dynamic_capacitance(df, I)

    append!(dyn_Cs[!, :Porosity], repeat([foldervalue(datafile)], length(V)))
    append!(dyn_Cs[!, :V], V)
    append!(dyn_Cs[!, :I], repeat([I], length(V)))
    append!(dyn_Cs[!, :C], Cs)
end

function compute_capacitances(data, folder)
    grouped = groupbyfolder(data["C&D"])
    c_units = join(["V s","mA", replace_unicode("μF"), "F/g"], ',')
    dc_units = join(["-","V","mA", replace_unicode("μF")], ',')

    for (f, datafiles) in grouped
        capacitances = DataFrame(
            :Area=>Float64[],
            :I=>Float64[],
            :C_abs=>Float64[],
            :C=>Float64[])
        dynamic_capacitances = DataFrame(
            :Porosity=>String[],
            :V=>Float64[],
            :I=>Float64[],
            :C=>Float64[])

        for datafile in datafiles
            if endswith(datafile.filename, "_D")
                df = read_file(datafile)
                add_capacitance!(capacitances, datafile, df, folder)
                add_dyn_capacitance!(dynamic_capacitances, datafile, df)
            end
        end

        sort!(capacitances, :I)
        sort!(dynamic_capacitances, :V)
        comment = join(repeat([f*replace_powers(" mA cm^-2")], 4), ',')

        write_file(capacitances, (c_units,comment), joinpath(folder, f, "capacitances.csv"), ',')
        write_file(dynamic_capacitances, (dc_units,comment), joinpath(folder, f, "dynamic_capacitances.csv"), ',')
    end

    return nothing
end

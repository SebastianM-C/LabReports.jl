function cd_capacitance(df, I)
    t, V = df[!, Symbol("Time (s)")], df[!, Symbol("Potential (V)")]
    idxs = findall(v->v > 0, V)
    t, V = t[idxs], V[idxs]

    ∫Vdt = integrate(t, V) * u"V*s"
    Δt = (t[end] - t[begin]) * u"s"
    # ΔV = -(reverse(extrema(V))...)
    ΔV = 1.4u"V"

    return Δt, ΔV, ∫Vdt, 2*I*∫Vdt/ΔV^2
end

function sign_change(x, sgn::Pair{Symbol,Symbol})
    if sgn == (:- => :+)
        idx = sign_change(x, true)
    else
        idx = sign_change(x, false)
    end

    # Adjust to closest value
    inext = idx == lastindex(x) ? firstindex(x) : idx+1
    iprev = idx == firstindex(x) ? lastindex(x) : idx-1
    if abs(x[inext]) < abs(x[idx])
        idx = inext
    elseif abs(x[iprev]) < abs(x[idx])
        idx = iprev
    end

    return idx
end

function sign_change(x, sgn)
    if signbit(x[end]) == sgn
        # we consider peroidic boundary conditions
        start_idx = firstindex(x)
        xprev = x[end]
    elseif signbit(x[begin]) == sgn
        # we start on the correct sign
        start_idx = firstindex(x) + 1
        xprev = x[begin]
    else
        start_idx = firstindex(x)
        while signbit(x[start_idx]) ≠ sgn
            start_idx +=1
        end
        xprev = x[start_idx]
        start_idx += 1
    end
    sprev = signbit(xprev)
    @assert sprev == sgn
    idx = start_idx
    offset_x = OffsetArray(x[start_idx:end], start_idx:lastindex(x))
    for i in eachindex(offset_x)
        current_sign = signbit(x[i])
        if (current_sign ≠ sprev)
            idx = i
            break
        end
        xprev = x[i]
        sprev = current_sign
    end
    return idx
end

function discharge_area(df)
    I, V = df[!, Symbol("Current (mA)")], df[!, Symbol("Potential (V)")]
    t = df[!, Symbol("Time (s)")]

    # 4th quadrant
    a_idx = sign_change(I, :+ => :-)
    b_idx = sign_change(V, :+ => :-)
    @assert b_idx > a_idx

    I, V = I[a_idx:b_idx], V[a_idx:b_idx]
    # account for integrating "in reverse"
    sgn = V[begin] > V[end] ? -1 : 1
    ∫Idt = sgn * integrate(V, I) * u"V*A"
    Δt = (t[b_idx] - t[a_idx]) * u"s"
    ΔV = (V[end] - V[begin]) * u"V"

    return Δt, ΔV, ∫Idt
end

function cv_capacitance(df, scan_rate)
    Δt, ΔV, ∫Idt = discharge_area(df)

    C = ∫Idt / (ΔV * scan_rate)
    return Δt, ΔV, ∫Idt, C
end

function specific_capacitance(C, porosity, folder)
    A = 71u"cm^2"
    a = 0.5u"cm^2"

    df = CSV.read("$folder/weights.csv")
    mass = (df[!,:after].*u"g" .- df[!,:before].*u"g") .* a ./ A .|> u"μg"
    mass_dict = Dict([10,30,50,70,90,110].=>mass[1:6])

    C / mass_dict[porosity]
end

function energy(C, ΔV)
    return (C*ΔV^2)/2
end

power(E, Δt) = E / Δt

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

function add_capacitance!(capacitance, (par_name, par_units, area_units), Cs, datafile, df, folder, ext="")
    par = parse(Float64, filevalue(datafile, ext)) * uparse(datafile.legend_units)
    porosity = parse(Int, foldervalue(datafile))

    Δt, ΔV, area, C = capacitance(df, par)
    C_specific = specific_capacitance(C, porosity, folder)
    E = energy(C, ΔV)
    E_specific = energy(C_specific, ΔV)
    P = power(E, Δt)
    P_specific = power(E_specific, Δt)

    push!(Cs[!, :Area], ustrip(area_units, area))
    push!(Cs[!, :Δt], ustrip(u"s", Δt))
    push!(Cs[!, :ΔV], ustrip(u"V", ΔV))
    push!(Cs[!, par_name], ustrip(par_units, par))
    push!(Cs[!, :C], ustrip(u"μF", C))
    push!(Cs[!, :C_specific], ustrip(u"F/g", C_specific))
    push!(Cs[!, :E], ustrip(u"W*hr", E))
    push!(Cs[!, :E_specific], ustrip(u"W*hr/kg", E_specific))
    push!(Cs[!, :P], ustrip(u"W", P))
    push!(Cs[!, :P_specific], ustrip(u"W/kg", P_specific))

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

function compute_capacitances(folder)
    data = find_files(folder)
    processed_data = find_files(folder, exclude_with=r"!", select_with=".dat", rename=false)

    grouped = groupbyfolder(data["C&D"])
    processed_grouped = groupbyfolder(processed_data["CV"])
    @assert keys(grouped) == keys(processed_grouped)

    cd_c_units = join(["V s", "s", "V", "mA", replace_unicode("μF"), "F/g", "W*h", "Wh/kg", "W", "W/kg"], ',')
    cv_c_units = replace(cd_c_units, "mA"=>"mV/s")
    dc_units = join(["-","V","mA", replace_unicode("μF")], ',')

    for f in keys(grouped)
        cd_datafiles = grouped[f]
        cv_datafiles = processed_grouped[f]

        cd_capacitances = DataFrame(
            :Area=>Float64[],
            :Δt=>Float64[],
            :ΔV=>Float64[],
            :I=>Float64[],
            :C=>Float64[],
            :C_specific=>Float64[],
            :E=>Float64[],
            :E_specific=>Float64[],
            :P=>Float64[],
            :P_specific=>Float64[])
        cv_capacitances = rename(cd_capacitances, :I=>:scan_rate)
        dynamic_capacitances = DataFrame(
            :Porosity=>String[],
            :V=>Float64[],
            :I=>Float64[],
            :C=>Float64[])

        for datafile in cd_datafiles
            if endswith(datafile.filename, "_D")
                df = read_file(datafile)
                add_capacitance!(cd_capacitance, (:I, u"mA", u"V*s"), cd_capacitances, datafile, df, folder)
                add_dyn_capacitance!(dynamic_capacitances, datafile, df)
            end
        end

        for datafile in cv_datafiles
            df = read_file(datafile, 3, false)
            add_capacitance!(cv_capacitance, (:scan_rate, u"mV/s", u"V*A"), cv_capacitances, datafile, df, folder, ".dat")
        end

        rename_cols!(capacitances) = rename!(capacitances, Dict(
            "E_specific"=>"Energy density",
            "P_specific"=>"Power density",
            "C"=>"C_abs",
            "C_specific"=>"C",
            "Δt"=>replace_unicode("Δt"),
            "ΔV"=>replace_unicode("ΔV")))
        rename_cols!(cd_capacitances)
        rename_cols!(cv_capacitances)
        sort!(cd_capacitances, :I)
        sort!(cv_capacitances, :scan_rate)
        sort!(dynamic_capacitances, :V)

        comment(df) = join(repeat([f*replace_powers(" mA cm^-2")], size(df,2)), ',')

        write_file(
            cd_capacitances,
            (cd_c_units, comment(cd_capacitances)),
            joinpath(folder, f, "cd_capacitances.csv"),
            ',')
        write_file(
            cv_capacitances,
            (cv_c_units, comment(cv_capacitances)),
            joinpath(folder, f, "cv_capacitances.csv"),
            ',')
        write_file(
            dynamic_capacitances,
            (dc_units, comment(dynamic_capacitances)),
            joinpath(folder, f, "dynamic_capacitances.csv"),
            ',')
    end

    return nothing
end

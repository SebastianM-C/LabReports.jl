@with_kw struct CSetup{S,V}
    a::S = 0.5u"cm^2"
    A::S = 71.0u"cm^2"
    fixed_ΔV::V = nothing
end

function specific_capacitance(C, porosity, folder, a, A)
    porosities = sort!(parse.(Int, dirs_in_folder(folder, false)))

    df = CSV.read("$folder/weights.csv")
    mass = (df[!,:after].*u"g" .- df[!,:before].*u"g") .* a ./ A .|> u"μg"
    mass_dict = Dict(porosities.=>mass[1:length(porosities)])

    # @show mass_dict
    C / mass_dict[porosity]
end

function energy(C, ΔV)
    return (C*ΔV^2)/2
end

power(E, Δt) = E / Δt

function add_report!(df, cr)
    add_aux!(df, cr)

    push!(df[!, :C], ustrip(u"μF", cr.C))
    push!(df[!, :C_specific], ustrip(u"F/g", cr.C_specific))
    push!(df[!, :E], ustrip(u"W*hr", cr.E))
    push!(df[!, :E_specific], ustrip(u"W*hr/kg", cr.E_specific))
    push!(df[!, :P], ustrip(u"W", cr.P))
    push!(df[!, :P_specific], ustrip(u"W/kg", cr.P_specific))

    return nothing
end

function add_report!(result_df, datafile, folder, setup)
    if !datafile.is_charging
        df = read_file(datafile)
        cr = CDCapacitanceReport(datafile, df, folder, setup)
        add_report!(result_df, cr)
    end
end

function add_report!(result_df, datafile, quadrant, folder, setup)
    df = read_file(datafile, processed_datarow, false)
    if size(df, 1) < 4
        @warn("Too few datapoints for $(datafile.filename)")
        return
    end
    cr = CVCapacitanceReport(datafile, df, quadrant, folder, setup)
    add_report!(result_df, cr)
end

function compute_capacitances(folder, spec; cv_setup=[CSetup(),CSetup()], cd_setup=CSetup(),
        extra_rules=(), processed_extra_rules=extra_rules, exclude_dirs=[])
    data = find_files(folder, spec, extra_rules=extra_rules, exclude_with=[".dat",".csv"], exclude_dirs=exclude_dirs)
    processed_data = find_files(folder, spec, extra_rules=processed_extra_rules, exclude_dirs=exclude_dirs,
        exclude_with=[r"!"], select_with=".dat")

    grouped = groupby(foldervalue, groupby(filetype, data)["C&D"])
    processed_grouped = groupby(foldervalue, groupby(filetype, processed_data)["CV"])

    cd_units = cd_report_units()
    cv_units = cv_report_units()


    for f in keys(grouped)
        cd_name = joinpath(folder, string(Int(ustrip(f))), "cd_capacitances.csv")
        df = compute_capacitances(folder, grouped, f, cd_result, cd_setup, nothing)
        write_capacitance(df, cd_name, :I, cd_units, f)
    end
    for f in keys(processed_grouped)
        cv_name1 = joinpath(folder, string(Int(ustrip(f))), "cv_capacitances4.csv")
        cv_name2 = joinpath(folder, string(Int(ustrip(f))), "cv_capacitances2.csv")
        df1 = compute_capacitances(folder, processed_grouped, f, cv_result, cv_setup[1], 4)
        df2 = compute_capacitances(folder, processed_grouped, f, cv_result, cv_setup[2], 2)
        write_capacitance(df1, cv_name1, :scan_rate, cv_units, f)
        write_capacitance(df2, cv_name2, :scan_rate, cv_units, f)
    end

    return nothing
end

function write_capacitance(report, name, sort_col, units, key)
    rename_cols!(df) = rename!(df, Dict(
        "E_specific"=>"Energy density",
        "P_specific"=>"Power density",
        "C"=>"C_abs",
        "C_specific"=>"C",
        "Δt"=>replace_unicode("Δt"),
        "ΔV"=>replace_unicode("ΔV")))
    rename_cols!(report)
    sort!(report, sort_col)

    comment(df) = join(repeat([replace_powers(string(key))], size(df,2)), ',')

    write_file(
        report,
        (units, comment(report)),
        name,
        ',')
end

function compute_capacitances(folder, grouped, key, result_f, c_setup, idx)
    datafiles = grouped[key]

    report = result_f()

    for datafile in datafiles
        if isnothing(idx)
            add_report!(report, datafile, folder, c_setup)
        else
            add_report!(report, datafile, idx, folder, c_setup)
        end
    end

    return report
end

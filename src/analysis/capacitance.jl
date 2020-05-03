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
    if endswith(datafile.filename, "_D")
        df = read_file(datafile)
        cr = CDCapacitanceReport(datafile, df, folder, setup)
        add_report!(result_df, cr)
    end
end

function add_report!(result_df, datafile, quadrant, folder, setup)
    df = read_file(datafile, 3, false)
    cr = CVCapacitanceReport(datafile, df, quadrant, folder, setup)
    add_report!(result_df, cr)
end

function compute_capacitances(folder; cv_setup=CSetup(), cd_setup=CSetup())
    data = find_files(folder)
    processed_data = find_files(folder, exclude_with=r"!", select_with=".dat", rename=false)

    grouped = groupbyfolder(data["C&D"])
    processed_grouped = groupbyfolder(processed_data["CV"])
    @assert keys(grouped) == keys(processed_grouped)

    cd_units = cd_report_units()
    cv_units = cv_report_units()

    for f in keys(grouped)
        cd_datafiles = grouped[f]
        cv_datafiles = processed_grouped[f]

        cd_report = cd_result()
        cv_report4 = cv_result()
        cv_report2 = cv_result()

        for datafile in cd_datafiles
            add_report!(cd_report, datafile, folder, cd_setup)
        end

        for datafile in cv_datafiles
            add_report!(cv_report4, datafile, 4, folder, cv_setup)
            add_report!(cv_report2, datafile, 2, folder, cv_setup)
        end

        rename_cols!(df) = rename!(df, Dict(
            "E_specific"=>"Energy density",
            "P_specific"=>"Power density",
            "C"=>"C_abs",
            "C_specific"=>"C",
            "Δt"=>replace_unicode("Δt"),
            "ΔV"=>replace_unicode("ΔV")))
        rename_cols!(cd_report)
        rename_cols!(cv_report4)
        rename_cols!(cv_report2)
        sort!(cd_report, :I)
        sort!(cv_report4, :scan_rate)
        sort!(cv_report2, :scan_rate)

        comment(df) = join(repeat([f*replace_powers(" mA cm^-2")], size(df,2)), ',')

        write_file(
            cd_report,
            (cd_units, comment(cd_report)),
            joinpath(folder, f, "cd_capacitances.csv"),
            ',')
        write_file(
            cv_report4,
            (cv_units, comment(cv_report4)),
            joinpath(folder, f, "cv_capacitances4.csv"),
            ',')
        write_file(
            cv_report2,
            (cv_units, comment(cv_report2)),
            joinpath(folder, f, "cv_capacitances2.csv"),
            ',')
    end

    return nothing
end

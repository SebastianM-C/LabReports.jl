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

function add_report!(result_df, datafile, folder, fixed_ΔV)
    if endswith(datafile.filename, "_D")
        df = read_file(datafile)
        cr = CDCapacitanceReport(datafile, df, folder, fixed_ΔV)
        add_report!(result_df, cr)
    end
end

function add_report!(result_df, datafile, quadrant, folder, fixed_ΔV)
    df = read_file(datafile, 3, false)
    cr = CVCapacitanceReport(datafile, df, quadrant, folder, fixed_ΔV)
    add_report!(result_df, cr)
end

function compute_capacitances(folder; cv_ΔV=nothing, cd_ΔV=nothing)
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
            add_report!(cd_report, datafile, folder, cd_ΔV)
        end

        for datafile in cv_datafiles
            add_report!(cv_report4, datafile, 4, folder, cv_ΔV)
            add_report!(cv_report2, datafile, 2, folder, cv_ΔV)
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
        rename_cols!(cv_report4)
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

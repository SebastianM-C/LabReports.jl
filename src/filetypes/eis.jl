struct ElectrochemicalImpedanceSpectroscopy{Q} <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    U::Q
    porosity::Quantity
    exposure_time::Quantity
    round_idx::Int
    name_rules::NamedTuple
    spec::String
end

function ElectrochemicalImpedanceSpectroscopy(filename, savename, units, spec, name_rules)
    round_idx = 1
    spec = replace(spec, "{val}"=>"{U}")
    m = match_spec(spec, filename, parse_rules)
    isnothing(m) && @error "Specification string $spec did not match filename for $filename"

    U = parse_quantity(m, :U, name_rules)
    porosity = parse_quantity(m, :porosity, name_rules, Int)
    exposure_time = parse_quantity(m, :exposure_time, name_rules)

    ElectrochemicalImpedanceSpectroscopy(filename, savename, units, U, porosity,
        exposure_time, round_idx, name_rules, spec)
end

function DataFrames.rename!(df, ::ElectrochemicalImpedanceSpectroscopy)
    namemap = Dict("Z'"=>"ReZ",
                   "-Z''"=>"ImZ")
    rename!(df, namemap)
end

function process_data(data::ElectrochemicalImpedanceSpectroscopy; select)
    col, op, val = select
    df = read_file(data)
    c = getproperty(df, col)
    fd = getindex(df, op.(c, val), :)

    write_file(data, fd, ';')
end

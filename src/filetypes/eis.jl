struct ElectrochemicalImpedanceSpectroscopy{Q} <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    U::Q
    porosity::Quantity
    round_idx::Int
    name_rules::NamedTuple
end

function ElectrochemicalImpedanceSpectroscopy(filename, savename, units, name_rules)
    round_idx = 1
    name_rules = merge(name_rules, (U=name_rules.val,))
    U = parse_quantity(filename, name_rules, :U)
    porosity = parse_quantity(filename, name_rules, :porosity)

    ElectrochemicalImpedanceSpectroscopy(filename, savename, units, U, porosity, round_idx, name_rules)
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

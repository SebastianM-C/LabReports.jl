struct ElectrochemicalImpedanceSpectroscopy <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    U::Quantity
    porosity::Quantity
    round_idx::Int
    name_rules::NamedTuple
end

function ElectrochemicalImpedanceSpectroscopy(filename, savename, units, name_rules)
    round_idx = 1
    U = uparse(filevalue(filename, name_rules))
    porosity = parse(Float64, foldervalue(filename)) * u"mA/cm^2"

    ElectrochemicalImpedanceSpectroscopy(filename, savename, units, U, porosity, round_idx, name_rules)
end

function DataFrames.rename!(df, ::ElectrochemicalImpedanceSpectroscopy) end

function process_data(data::ElectrochemicalImpedanceSpectroscopy; select)
    col, op, val = select
    df = read_file(data)
    c = getproperty(df, col)
    fd = getindex(df, op.(c, val), :)

    write_file(data, fd, ';')
end

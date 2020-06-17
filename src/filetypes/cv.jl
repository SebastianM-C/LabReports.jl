struct CiclycVoltammetry <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    scan_rate::Quantity
    porosity::Quantity
    round_idx::Int
    name_rules::NamedTuple
end

function CiclycVoltammetry(filename, savename, units, name_rules)
    round_idx = 2
    scan_rate = parse(Float64, filevalue(filename, name_rules)) * u"mV/s"
    porosity  = parse(Float64, foldervalue(filename)) * u"mA/cm^2"

    CiclycVoltammetry(filename, savename, units, scan_rate, porosity, round_idx, name_rules)
end

function DataFrames.rename!(df, ::CiclycVoltammetry)
    namemap = Dict("WE(1).Current"=>"Current",
                   "WE(1).Potential"=>"Potential")
    rename!(df, namemap)
end

function process_data(data::CiclycVoltammetry; select)
    col, op, val = select
    df = read_file(data)
    c = getproperty(df, col)
    fd = getindex(df, op.(c, val), :)
    push!(fd, fd[1, :])
    # convert to mA
    idx = findfirst(n->n=="Current", names(fd))
    fd[!, :Current] .*= ustrip(u"mA", 1data.units[idx])
    data.units[idx] = u"mA"

    write_file(data, fd, ';')
end

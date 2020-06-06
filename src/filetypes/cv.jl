struct CiclycVoltammetry <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    scan_rate::Quantity
    round_idx::Int
    name_rules::NamedTuple
end

function CiclycVoltammetry(filename, savename, units, name_rules)
    legend_units = u"mV/s"
    round_idx = 2
    val = filevalue(filename, name_rules)
    scan_rate = parse(Float64, val) * legend_units

    CiclycVoltammetry(filename, savename, units, scan_rate, round_idx, name_rules)
end

function DataFrames.rename!(df, ::CiclycVoltammetry)
    namemap = Dict("WE(1).Current"=>"Current",
                   "WE(1).Potential"=>"Potential")
    rename!(df, namemap)
end

function process_data(::Val{:CV}, data; select)
    col, op, val = select
    for f in data["CV"]
        df = read_file(f)
        c = getproperty(df, col)
        fd = getindex(df, op.(c, val), :)
        push!(fd, fd[1, :])

        write_file(f, fd, ';')
    end
end

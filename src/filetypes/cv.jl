struct CiclycVoltammetry <: AbstractDataFile
    filename::String
    savename::String
    units::Vector{Unitful.Units}
    scan_rate::Quantity
    porosity::Quantity
    exposure_time::Quantity
    round_idx::Int
    name_rules::NamedTuple
    spec::String
end

function CiclycVoltammetry(filename, savename, units, spec, name_rules)
    round_idx = 2
    spec = replace(spec, "{val}"=>"{scan_rate}")
    m = match_spec(spec, filename, parse_rules)
    isnothing(m) && @error "Specification string $spec did not match filename for $filename"

    scan_rate = parse_quantity(m, :scan_rate, name_rules)
    porosity = parse_quantity(m, :porosity, name_rules, Int)
    exposure_time = parse_quantity(m, :exposure_time, name_rules)

    CiclycVoltammetry(filename, savename, units, scan_rate, porosity,
        exposure_time, round_idx, name_rules, spec)
end

function DataFrames.rename!(df, ::CiclycVoltammetry)
    namemap = Dict("WE(1).Current"=>"Current",
                   "WE(1).Potential"=>"Potential")
    rename!(df, namemap)
end

function process_data(data::CiclycVoltammetry; select)
    # col, op, val = select
    # df = read_file(data)
    # c = getproperty(df, col)
    # fd = getindex(df, op.(c, val), :)
    # push!(fd, fd[1, :])
    if !isnothing(select)
        df = select_data(data, select)
    else
        df = select_data(data)
    end

    push!(df, df[1, :])
    # convert to mA
    idx = findfirst(n->n=="Current", names(df))
    df[!, :Current] .*= ustrip(u"mA", 1data.units[idx])
    original_units = data.units[idx]
    data.units[idx] = u"mA"

    write_file(data, df, ';')
    data.units[idx] = original_units

    return nothing
end

function select_data(data, select)
    col, op, val = select
    df = read_file(data)
    c = getproperty(df, col)
    fd = getindex(df, op.(c, val), :)

    return fd
end

function select_data(data)
    df = read_file(data)
    idx = 0
    for i in 2:size(df, 1)
        if df[!, "Potential"][i-1] < 0 && df[!, "Potential"][i] > 0
            idx = i
            break
        end
    end

    return df[idx:end, :]
end

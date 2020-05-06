struct CVCapacitanceReport{U1,U2,U3,U4,U5,U6,U7,U8,U9,U10}
    Δt::U1
    ΔV::U2
    area::U3
    scan_rate::U4
    quadrant::Int
    C::U5
    C_specific::U6
    E::U7
    E_specific::U8
    P::U9
    P_specific::U10
end

function capacitance(df, scan_rate, quadrant, fixed_ΔV)
    Δt, ΔV, ∫IdV = discharge_area(df, quadrant, fixed_ΔV)

    C = ∫IdV / (ΔV * scan_rate)
    return Δt, ΔV, ∫IdV, C
end

function CVCapacitanceReport(datafile, df, quadrant, folder, setup)
    ext = ".dat"    # using processed data
    scan_rate = parse(Float64, filevalue(datafile, ext)) * uparse(datafile.legend_units)
    porosity = parse(Int, foldervalue(datafile))
    @unpack a, A, fixed_ΔV = setup

    Δt, ΔV, area, C = capacitance(df, scan_rate, quadrant, fixed_ΔV)
    C_specific = specific_capacitance(C, porosity, folder, a, A)
    E = energy(C, ΔV)
    E_specific = energy(C_specific, ΔV)
    P = power(E, Δt)
    P_specific = power(E_specific, Δt)

    CVCapacitanceReport(Δt, ΔV, area, scan_rate, quadrant, C, C_specific, E, E_specific, P, P_specific)
end

function add_aux!(df, cr::CVCapacitanceReport)
    push!(df[!, :Area], ustrip(u"V*A", cr.area))
    push!(df[!, :quadrant], cr.quadrant)
    push!(df[!, :Δt], ustrip(u"s", cr.Δt))
    push!(df[!, :ΔV], ustrip(u"V", cr.ΔV))
    push!(df[!, :scan_rate], ustrip(u"mV/s", cr.scan_rate))

    return nothing
end

function cv_report_units()
    join(["V A", "", "s", "V", "mV/s", replace_unicode("μF"), "F/g", "W*h", "Wh/kg", "W", "W/kg"], ',')
end

function cv_result()
    DataFrame(
        :Area=>Float64[],
        :quadrant=>Int[],
        :Δt=>Float64[],
        :ΔV=>Float64[],
        :scan_rate=>Float64[],
        :C=>Float64[],
        :C_specific=>Float64[],
        :E=>Float64[],
        :E_specific=>Float64[],
        :P=>Float64[],
        :P_specific=>Float64[])
end

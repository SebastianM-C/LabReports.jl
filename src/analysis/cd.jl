struct CDCapacitanceReport{U1,U2,U3,U4,U5,U6,U7,U8,U9,U10}
    Δt::U1
    ΔV::U2
    area::U3
    I::U4
    C::U5
    C_specific::U6
    E::U7
    E_specific::U8
    P::U9
    P_specific::U10
end

function capacitance(df, I, fixed_ΔV)
    t, V = df[!, Symbol("Time")], df[!, Symbol("Potential")]
    idxs = findall(v->v > 0, V)
    t, V = t[idxs], V[idxs]

    ∫Vdt = integrate(t, V) * u"V*s"
    Δt = (t[end] - t[begin]) * u"s"
    ΔV = !isnothing(fixed_ΔV) ? fixed_ΔV : -(reverse(extrema(V))...)

    return Δt, ΔV, ∫Vdt, 2*I*∫Vdt/ΔV^2
end

function CDCapacitanceReport(datafile, df, folder, setup)
    @unpack I, porosity = datafile
    @unpack a, A, fixed_ΔV = setup

    Δt, ΔV, area, C = capacitance(df, I, fixed_ΔV)
    # C_specific = specific_capacitance(C, porosity, folder, a, A)
    C_specific = missing
    E = energy(C, ΔV)
    E_specific = energy(C_specific, ΔV)
    P = power(E, Δt)
    P_specific = power(E_specific, Δt)

    CDCapacitanceReport(Δt, ΔV, area, I, C, C_specific, E, E_specific, P, P_specific)
end

function add_aux!(df, cr::CDCapacitanceReport)
    push!(df[!, :Area], ustrip(u"V*s", cr.area))
    push!(df[!, :Δt], ustrip(u"s", cr.Δt))
    push!(df[!, :ΔV], ustrip(u"V", cr.ΔV))
    push!(df[!, :I], ustrip(u"mA", cr.I))

    return nothing
end

function cd_report_units()
    join(["V s", "s", "V", "mA", replace_unicode("μF"), "F/g", "W*h", "Wh/kg", "W", "W/kg"], ',')
end

function cd_result()
    DataFrame(
        :Area=>Float64[],
        :Δt=>Float64[],
        :ΔV=>Float64[],
        :I=>Float64[],
        :C=>Float64[],
        :C_specific=>Union{Float64,Missing}[],
        :E=>Float64[],
        :E_specific=>Union{Float64,Missing}[],
        :P=>Float64[],
        :P_specific=>Union{Float64,Missing}[])
end

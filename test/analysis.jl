using LabReports, Test
using CSV
using Unitful
using LabReports: sign_change, integration_domain, discharge_area, CVCapacitanceReport

@testset "IO" begin
    df = CSV.read("fake_data/15/15_EIS", delim=';', datarow=2, copycols=true)
    @test df == results("fake_data", "EIS", "15", "15", processed=false)[2]

    df = CSV.read("fake_data/15/15_CV_3.dat", delim=';', datarow=3, copycols=true)
    @test df == results("fake_data", "CV", "15", "3", processed=true)[2]
end

@testset "Area" begin
    df = results("fake_data", "CV", "15", "14000", processed=true)[2]

    I = df[!, Symbol("Current (mA)")]
    V = df[!, Symbol("Potential (V)")]

    @testset "sign_change" begin
        @test sign_change(V, :- => :+) == 55
        @test sign_change(V, :+ => :-) == 33
        @test sign_change(I, :+ => :-) == 20
        @test sign_change(I, :- => :+) == 50
    end

    @testset "integration_domain" begin
        @test integration_domain(V, I, 1, :orar) == (55, 20)
        @test integration_domain(V, I, 2, :orar) == (50, 55)
        @test integration_domain(V, I, 3, :orar) == (33, 50)
        @test integration_domain(V, I, 4, :orar) == (20, 33)
    end

    @testset "4th quadrant" begin
        Δt, ΔV, area = discharge_area(df, 4, nothing)
        @test Δt ≈ 0.1299999996717u"s"
        @test ΔV ≈ -2.613535594192u"V"
        @test area ≈ -0.00190424207227u"V*A"
    end

    @testset "4th quadrant, fixed ΔV" begin
        Δt, ΔV, area = discharge_area(df, 4, 1.5u"V")
        @test Δt ≈ 0.1299999996717u"s"
        @test ΔV ≈ -1.5u"V"
        @test area ≈ -0.00190424207227u"V*A"
    end
end

@testset "CV capacitance" begin
    datafile, df = results("fake_data", "CV", "15", "14000", processed=true)

    setup = CVSetup(a=0.1u"cm^2", A=10.0u"cm^2")
    cr = CVCapacitanceReport(datafile, df, 4, "fake_data", setup)
    @test cr.C ≈ 90.67819391u"μF"
    @test cr.C_specific ≈ 90678.19391788u"μF/g"
    @test cr.E ≈ 2.83369355e-8u"W*hr"
    @test cr.E_specific ≈ 0.0283369355u"W*hr/kg"
    @test cr.P ≈ 0.0007847151416u"W"
    @test cr.P_specific ≈ 784.71514165u"W/kg"
end

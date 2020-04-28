using LabReports, Test
using LabReports: replace_powers, to_origin, comment_value

@testset "replace_power" begin
    @test replace_powers("300 mV s^-1") == "300 mV/s"
    @test replace_powers("10 m^2") == "10 m\\+(2)"
    @test replace_powers("1 μA^-2") == "1 μA\\+(-2)"
    @test replace_powers("1 μA^2") == "1 μA\\+(2)"
    @test replace_powers("15 mA cm^-2") == "15 mA/cm\\+(2)"
end

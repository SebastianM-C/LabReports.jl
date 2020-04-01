using LabReports
using Test

@testset "LabReports.jl" begin
    const folder = "fake_data"

    data = find_files(folder)

    process_data("CV", data, (==, :Scan, 2))

    process_data("EIS", data, (>, Symbol("-Phase (°)"), 0))

    process_data("C&D", data, (0, 1.4, 0, 0, 0), Symbol("Time (s)"))
end

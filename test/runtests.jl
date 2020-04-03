using LabReports
using Test

@testset "LabReports.jl" begin
    folder = "fake_data"
    data = find_files(folder)

    process_data("CV", data, select=(:Scan, ==, 2))

    process_data("EIS", data, select=(Symbol("-Phase (°)"), >, 0))

    process_data("C&D", data, insert_D=(0, 1.4, 0, 0, 0), continue_col=Symbol("Time (s)"))

    clear(folder, r"filtered.*")
    mv("fake_data\\200\\200_C&D_3.4e-3_D", "fake_data\\200\\200_C&D_3.4e-3")
end

using LabReports
using Test

@testset "LabReports.jl" begin
    folder = "fake_data"
    reference_folder = "reference_data"
    to_rename = joinpath("fake_data", "200", "200_C&D_3.4e-3")
    renamed = joinpath("fake_data", "200", "200_C&D_3.4e-3_D")

    data = @test_logs (:info, "Renamed $to_rename to $renamed") find_files(folder)
    reference_data = find_files(reference_folder)

    @test length(data) == length(reference_data) == 3
    @testset "Find $k" for k in keys(data)
        for (datafile, ref) in zip(data[k], reference_data[k])
            @test basename(datafile.filename) == basename(ref.filename)
            @test basename(datafile.savename) == basename(ref.savename)
            @test datafile.units == ref.units
            @test datafile.legend_units == ref.legend_units
            @test datafile.idx == ref.idx
        end
    end

    process_data("CV", data, select=(:Scan, ==, 2))

    process_data("EIS", data, select=(Symbol("-Phase (°)"), >, 0))

    process_data("C&D", data, insert_D=(0, 1.4, 0, 0, 0), continue_col=Symbol("Time (s)"))

    for ((root,dirs,files),(ref_root,ref_dirs,ref_files)) in zip(walkdir(folder), walkdir(reference_folder))
        @test dirs == ref_dirs
        @test files == ref_files
        @testset "File comparison for $file" for (file, ref_file) in zip(files, ref_files)
            f = read(joinpath(root, file), String)
            r = read(joinpath(ref_root, ref_file), String)
            @test f == r
        end
    end

    # Cleanup
    clear(folder, r".*\.dat")
    mv(renamed, to_rename)
end

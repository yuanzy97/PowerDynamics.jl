using PowerModelsACDC

function power_flow(power_grid :: PowerGrid)
    global global_dict
    global ang_min, ang_max
    global max_gen
    global_dict = PowerModelsACDC.get_pu_bases(100, 320)
    global_dict["omega"] = 2π * 50

    ang_min = deg2rad(360)
    ang_max = deg2rad(-360)

    function make_branch_ac(data :: Dict{String, Any}, key_e :: Int,  line)
        data["f_bus"] = line.from
        data["t_bus"] = line.to
        data["source_id"] = Any["branch", key_e]
        data["index"] = key_e
        data["rate_a"] = 1
        data["rate_b"] = 1
        data["rate_c"] = 1
        data["c_rating_a"] = 1
        data["br_status"] = 1
        data["angmin"] = ang_min
        data["angmax"] = ang_max

        # default values
        data["transformer"] = false
        data["tap"] = 1
        data["shift"] = 0
        data["g_fr"] = 0
        data["b_fr"] = 0
        data["g_to"] = 0
        data["b_to"] = 0

        Z = global_dict["Z"]

        if isa(line, StaticLine)
            data["br_r"] = real(1/line.Y/Z)
            data["br_x"] = imag(1/line.Y/Z)
        elseif isa(line, RLLine)
            data["br_r"] = real(line.R/Z)
            data["br_x"] = imag(line.L*line.ω0/Z)
        elseif isa(line, Transformer)
            data["transformer"] = true
            data["tap"] = line.t_ratio
            data["br_r"] = real(1/line.Y/Z)
            data["br_x"] = imag(1/line.Y/Z)
        elseif isa(line, PiModel)
            data["transformer"] = true
            data["tap"] = line.t_km / line.t_mk
            data["g_fr"] = real(line.y_shunt_km*Z / data["tap"]^2)
            data["b_fr"] = imag(line.y_shunt_km*Z / data["tap"]^2)
            data["br_r"] = real(1/line.Y/Z)
            data["br_x"] = imag(1/line.Y/Z)
            data["g_to"] = real(line.y_shunt_mk*Z)
            data["b_to"] = imag(line.y_shunt_mk*Z)
        elseif isa(line, PiModelLine)
            data["g_fr"] = real(line.y_shunt_km*Z)
            data["b_fr"] = imag(line.y_shunt_km*Z)
            data["br_r"] = real(1/line.Y/Z)
            data["br_x"] = imag(1/line.Y/Z)
            data["g_to"] = real(line.y_shunt_mk*Z)
            data["b_to"] = imag(line.y_shunt_mk*Z)
        else
            throw(ArgumentError("Line type $(typeof(line)) does not exist."))
        end
    end



    data = Dict{String, Any}()
    data["source_type"] = "matpower"
    data["name"] = "network"
    data["source_version"] = "0.0.0"
    data["per_unit"] = true
    data["dcpol"] = 2 # bipolar converter topologym check in the future
    data["baseMVA"] = global_dict["S"] / 1e6
    keywords = ["bus"; "busdc"; "shunt"; "dcline";
                "storage"; "switch"; "load"; "branch"; "branchdc";
                "gen"; "convdc"]
    for keyword in keywords
        data[keyword] = Dict{String, Any}()
    end

    for line in power_grid.lines
        key_e = length(data["branch"])+1
        (data["branch"])[string(key_e)] = Dict{String, Any}()
        make_branch_ac((data["branch"])[string(key_e)], key_e, line)
    end

    return data
end

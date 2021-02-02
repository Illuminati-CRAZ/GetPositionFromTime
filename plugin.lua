time = 0

current_position = 0
time_position = 0
selected_position = nil

range_start = 0
range_stop = 0
target_position = 0
desired_times = {}
positions = {}

window_hovered = false

--debug = "hi"

function draw()
    window_hovered = false
    draw1()
    draw2()
    state.IsWindowHovered = window_hovered
end

function draw1()
    imgui.Begin("GetPositionFromTime")

    window_hovered = imgui.IsWindowHovered()

    if current_position then imgui.Text("Current Position: " .. current_position) end
    if time_position then imgui.Text("Time Position: " .. time_position) end
    if selected_position then imgui.Text("Selected Position: " .. selected_position) end

    _, time = imgui.InputFloat("Time", time, 1)

    if imgui.Button("Update") then Update() end

    imgui.End()
end

function draw2()
    imgui.Begin("GetTimeFromPosition")

    window_hovered = imgui.IsWindowHovered() or window_hovered

    if imgui.Button("Current") then range_start = state.SongTime end imgui.SameLine()
    _, range_start = imgui.InputFloat("Range Start", range_start, 1)
    if imgui.Button("Current##1") then range_stop = state.SongTime end imgui.SameLine()
    _, range_stop = imgui.InputFloat("Range Stop", range_stop, 1)
    _, target_position = imgui.InputInt("Target Position", target_position, 100)

    if imgui.Button("Search") then
        desired_times--[[, positions]] = getTimesFromPosition(target_position, range_start, range_stop)
    end

    --[[if #positions > 0 then
        imgui.Text("min position: " .. math.min(unpack(positions)))
        imgui.Text("max position: " .. math.max(unpack(positions)))
    end]]--

    for _, time in pairs(desired_times) do
        imgui.Text(time)
    end

    imgui.End()
end

function getPositionFromTime(time)
    --[[
        if using this function multiple times in one frame,
        it may be faster to set ScrollVelocities = map.ScrollVelocities in draw()
        and then set local svs = ScrollVelocities inside this function
    ]]
    local svs = map.ScrollVelocities

    if #svs == 0 or time < svs[1].StartTime then
        return math.floor(time * 100)
    end

    local position = math.floor(svs[1].StartTime * 100)

    local i = 2

    while i <= #svs do
        if time < svs[i].StartTime then
            break
        else
            position = position + math.floor((svs[i].StartTime - svs[i - 1].StartTime) * svs[i - 1].Multiplier * 100)
        end

        i = i + 1
    end

    i = i - 1

    position = position + math.floor((time - svs[i].StartTime) * svs[i].Multiplier * 100)
    return position
end

function getTimesFromPosition(target_position, range_start, range_stop)
    range_start = range_start or -1e304
    range_stop = range_stop or -1e304

    local svs = {}
    local positions = {}

    local desired_times = {}

    svs[1] = utils.CreateScrollVelocity(range_start, map.GetScrollVelocityAt(range_start).Multiplier)
    for _, sv in pairs(map.ScrollVelocities) do
        if sv.StartTime >= range_stop then break end
        if sv.StartTime > range_start then
            table.insert(svs, sv)
        end
    end
    table.insert(svs, utils.CreateScrollVelocity(range_stop, map.GetScrollVelocityAt(range_stop).Multiplier))

    positions[1] = getPositionFromTime(range_start)
    for i = 2, #svs do
        local length = svs[i].StartTime - svs[i - 1].StartTime
        local distance = length * svs[i - 1].Multiplier * 100
        local position = positions[i - 1] + distance

        positions[i] = position
    end

    for i = 2, #positions do
        if positions[i - 1] <= target_position and target_position <= positions[i] then
            local desired_time = (target_position - positions[i - 1]) / 100 / svs[i - 1].Multiplier + svs[i - 1].StartTime
            table.insert(desired_times, desired_time)
        end
    end

    return desired_times--, positions
end

function Update()
    current_position = getPositionFromTime(state.SongTime)
    time_position = getPositionFromTime(time)
    if state.SelectedHitObjects[1] then selected_position = getPositionFromTime(state.SelectedHitObjects[1].StartTime)
    else selected_position = nil end
end
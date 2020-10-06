function draw()
    imgui.Begin("getPositionFromTime()")

    state.IsWindowHovered = imgui.IsWindowHovered()

    local position1 = getPositionFromTime(state.SongTime)
    local position2 = getPositionFromTime(state.SongTime - 10)

    imgui.Text("Current Position: " .. position1)
    imgui.Text("10 ms Delta: " .. position1 - position2)

    if state.SelectedHitObjects then
        imgui.Text("Selected Note Time: " .. state.SelectedHitObjects[1].StartTime)
        imgui.Text("Selected Note Position: " .. getPositionFromTime(state.SelectedHitObjects[1].StartTime))
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

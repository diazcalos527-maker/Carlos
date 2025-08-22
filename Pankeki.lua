local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local invisible = false

local function setInvisible(state)
    local char = player.Character or player.CharacterAdded:Wait()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = state and 1 or 0
        end
    end
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.X then
        invisible = not invisible
        setInvisible(invisible)
    end
end)

player.CharacterAdded:Connect(function(char)
    if invisible then
        task.wait(0.5)
        setInvisible(true)
    end
end)

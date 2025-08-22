-- Script de invisibilidad para TU juego
-- Coloca este Script en StarterCharacterScripts

local player = game.Players.LocalPlayer
local char = script.Parent

-- Función para volverse invisible
local function setInvisible(state)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.Transparency = state and 1 or 0 -- invisible si state = true
		end
		if part:IsA("ParticleEmitter") or part:IsA("Trail") then
			part.Enabled = not state
		end
	end
end

-- Activar invisibilidad después de 5 segundos como ejemplo
task.wait(5)
setInvisible(true)

-- Volver a visible después de 10 segundos
task.wait(10)
setInvisible(false)

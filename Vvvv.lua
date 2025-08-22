--[[ 
  Fly LocalScript (colócalo en StarterPlayerScripts)
  Controles:
    F       -> Alternar vuelo
    WASD    -> Moverse (relativo a la cámara)
    Space   -> Subir
    LeftCtrl-> Bajar
    LeftShift -> Sprint (multiplica la velocidad)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer

-- Ajustes
local BASE_SPEED = 50          -- Velocidad base (studs/seg)
local SPRINT_MULT = 2          -- Multiplicador con Shift
local ACCEL = 20               -- Suavizado (más alto = más inmediato)
local TOGGLE_KEY = Enum.KeyCode.F

-- Estado
local flying = false
local moveDir = Vector3.zero
local targetVel = Vector3.zero
local currentVel = Vector3.zero
local sprinting = false
local upPressed, downPressed = false, false

-- Referencias runtime
local character, humanoid, hrp, cam
local vforce -- VectorForce para anular gravedad
local att -- Attachment para VectorForce
local connRender

-- Helpers
local function getCharacter()
	if not LocalPlayer.Character or not LocalPlayer.Character.Parent then
		return nil
	end
	return LocalPlayer.Character
end

local function ensureRefs()
	character = getCharacter()
	if not character then return end

	humanoid = character:FindFirstChildOfClass("Humanoid")
	hrp = character:FindFirstChild("HumanoidRootPart")
	cam = workspace.CurrentCamera

	if humanoid and hrp then
		-- Crear VectorForce que compense la gravedad cuando volamos
		if not att then
			att = Instance.new("Attachment")
			att.Name = "FlyAttachment"
			att.Parent = hrp
		end
		if not vforce then
			vforce = Instance.new("VectorForce")
			vforce.Name = "FlyAntiGravity"
			vforce.Attachment0 = att
			vforce.RelativeTo = Enum.ActuatorRelativeTo.World
			vforce.Enabled = false
			vforce.Parent = hrp
		end
	end
end

local function cleanupForces()
	if vforce then vforce.Enabled = false end
	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function setFlying(enabled)
	flying = enabled and true or false
	if not humanoid or not hrp then return end

	if flying then
		-- Activar anti-gravedad (igual a masa * gravedad)
		local mass = hrp.AssemblyMass
		vforce.Force = Vector3.new(0, workspace.Gravity * mass, 0)
		vforce.Enabled = true

		-- Evitar animaciones de caminar/caer
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true

		-- Reiniciar velocidades
		currentVel = Vector3.zero
		targetVel = Vector3.zero

		-- Comenzar bucle de movimiento
		if not connRender then
			connRender = RunService:BindToRenderStep("FlyStep", Enum.RenderPriority.Character.Value + 1, function(dt)
				if not cam or not hrp then return end

				-- Dirección de cámara (plana para horizontal)
				local look = cam.CFrame.LookVector
				local right = cam.CFrame.RightVector
				local up = Vector3.new(0, 1, 0)

				-- Construir vector deseado a partir de inputs
				local wish = (look * moveDir.Z) + (right * moveDir.X)

				-- Altura (Espacio/Ctrl)
				if upPressed then
					wish += up
				end
				if downPressed then
					wish -= up
				end

				if wish.Magnitude > 0 then
					wish = wish.Unit
				end

				local speed = BASE_SPEED * (sprinting and SPRINT_MULT or 1)
				targetVel = wish * speed

				-- Suavizado
				local alpha = math.clamp(ACCEL * dt, 0, 1)
				currentVel = currentVel:Lerp(targetVel, alpha)

				-- Aplicar velocidad lineal al HRP
				hrp.AssemblyLinearVelocity = Vector3.new(
					currentVel.X,
					currentVel.Y,  -- ya que anulamos gravedad, el eje Y se controla
					currentVel.Z
				)
			end)
		end
	else
		-- Apagar vuelo
		if connRender then
			RunService:UnbindFromRenderStep("FlyStep")
			connRender = nil
		end
		cleanupForces()
	end
end

-- Input handlers
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TOGGLE_KEY then
		setFlying(not flying)
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		sprinting = true
	elseif input.KeyCode == Enum.KeyCode.W then
		moveDir = Vector3.new(moveDir.X, 0, -1)
	elseif input.KeyCode == Enum.KeyCode.S then
		moveDir = Vector3.new(moveDir.X, 0, 1)
	elseif input.KeyCode == Enum.KeyCode.A then
		moveDir = Vector3.new(-1, 0, moveDir.Z)
	elseif input.KeyCode == Enum.KeyCode.D then
		moveDir = Vector3.new(1, 0, moveDir.Z)
	elseif input.KeyCode == Enum.KeyCode.Space then
		upPressed = true
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		downPressed = true
	end
end

local function onInputEnded(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprinting = false
	elseif input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
		moveDir = Vector3.new(moveDir.X, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
		moveDir = Vector3.new(0, 0, moveDir.Z)
	elseif input.KeyCode == Enum.KeyCode.Space then
		upPressed = false
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		downPressed = false
	end
end

-- Re-setup al respawn
local function onCharacterAdded()
	task.wait(0.1)
	ensureRefs()
	setFlying(false)
end

-- Conexiones
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Inicialización
ensureRefs()
setFlying(false)

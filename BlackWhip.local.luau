local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

-- Referência ao RemoteEvent do Blackwhip
local RemoteEvent = ReplicatedStorage:WaitForChild("BlackWhip"):WaitForChild("BlackwhipRemoteEvent")

local Animation = Instance.new("Animation")
Animation.AnimationId = "rbxassetid://93772100288509"

local activeKeys = {}
local animators = {}
local animTracks = {}
local isHolding = {}
local lockedTargets = {}
local attached = {} -- [humanoid] = count
local isBlackwhipActive = false
local currentTarget = nil
local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineTransparency = 0
highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
highlight.Enabled = false
highlight.Parent = workspace

local function getArm(character, side)
	if side == "Right" then
		return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	else
		return character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	end
end

local function playAnimation(side)
	local character = player.Character or player.CharacterAdded:Wait()
	if not animators[side] then
		local humanoid = character:WaitForChild("Humanoid")
		animators[side] = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	end
	if not animTracks[side] then
		animTracks[side] = animators[side]:LoadAnimation(Animation)
	end
	if animTracks[side] and not animTracks[side].IsPlaying then
		animTracks[side]:Play()
	end
end

local function stopAnimation(side)
	if animTracks[side] and animTracks[side].IsPlaying then
		animTracks[side]:Stop()
	end
	activeKeys[side] = nil
	isHolding[side] = nil
end

local function getTarget()
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {player.Character or {}}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local rayResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
	if rayResult then
		local hitPart = rayResult.Instance
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				return humanoid
			end
		end
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Five then
		local fullCowlState = character:FindFirstChild("FullCowlActive")
		if fullCowlState then
			print("Client: Estado do Full Cowl:", fullCowlState.Value)
			if fullCowlState.Value then
				print("Client: Enviando ToggleBlackwhip para o servidor")
				RemoteEvent:FireServer("ToggleBlackwhip")
			else
				warn("Full Cowl deve estar ativo para usar o Blackwhip.")
			end
		else
			warn("Client: FullCowlActive não encontrado")
		end
	elseif isBlackwhipActive and (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E) then
		local side = (input.KeyCode == Enum.KeyCode.Q) and "Left" or "Right"
		if activeKeys[side] then return end
		local target = getTarget()
		if target then
			activeKeys[side] = true
			isHolding[side] = true
			lockedTargets[side] = target
			playAnimation(side)
			print("Client: Enviando UseBlackwhip para o servidor com alvo:", target, "lado:", side)
			RemoteEvent:FireServer("UseBlackwhip", target, side, true)
			attached[target] = (attached[target] or 0) + 1
			highlight.Adornee = target.Parent
			highlight.Enabled = true
			highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
			currentTarget = target
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not isBlackwhipActive then return end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
		local side = (input.KeyCode == Enum.KeyCode.Q) and "Left" or "Right"
		if activeKeys[side] then
			isHolding[side] = false
			print("Client: Enviando UseBlackwhip para o servidor para liberar:", side)
			RemoteEvent:FireServer("UseBlackwhip", nil, side, false)
			stopAnimation(side)
			local target = lockedTargets[side]
			if target then
				attached[target] = attached[target] - 1
				if attached[target] <= 0 then
					attached[target] = nil
				end
				lockedTargets[side] = nil
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not isBlackwhipActive then
		highlight.Enabled = false
		currentTarget = nil
		return
	end
	local target = getTarget()
	if target and target ~= currentTarget then
		highlight.Adornee = target.Parent
		highlight.Enabled = true
		local color = ((attached[target] or 0) > 0) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		highlight.OutlineColor = color
		currentTarget = target
	elseif not target and currentTarget then
		highlight.Enabled = false
		currentTarget = nil
	end
end)

RemoteEvent.OnClientEvent:Connect(function(action, value1)
	print("Client: Recebido do servidor:", action, value1)
	if action == "BlackwhipToggled" then
		local previousState = isBlackwhipActive
		isBlackwhipActive = value1
		if not isBlackwhipActive and previousState then
			for side in pairs(activeKeys) do
				if activeKeys[side] then
					isHolding[side] = false
					stopAnimation(side)
					RemoteEvent:FireServer("UseBlackwhip", nil, side, false)
				end
			end
			activeKeys = {}
			lockedTargets = {}
			attached = {}
			highlight.Enabled = false
			currentTarget = nil
		end
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	isBlackwhipActive = false
end)

player.CharacterRemoving:Connect(function()
	isBlackwhipActive = false
	lockedTargets = {}
	attached = {}
	highlight.Enabled = false
	currentTarget = nil
end)
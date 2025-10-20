local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RemoteEvent = ReplicatedStorage.FaJin:WaitForChild("FaJinRemoteEvent")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local leftEnergy = 0
local rightEnergy = 0
local lastFPressedTime = nil
local canUseCombo = true
local isFaJinActive = false
local controlPressed = false
local isCharging = false
local chargeStartTime = 0
local lastUpdateTime = 0
local updateInterval = 0.5
local chargeAnimTrack

local pressedKeys = {}

local function blockMovement(actionName, inputState, inputObject)
	return Enum.ContextActionResult.Sink
end

local function playChargeAnimation()
	if chargeAnimTrack then chargeAnimTrack:Stop() end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://110125779095007"
	chargeAnimTrack = humanoid:LoadAnimation(anim)
	chargeAnimTrack.Priority = Enum.AnimationPriority.Action
	chargeAnimTrack:Play()
end

local function stopChargeAnimation()
	if chargeAnimTrack then
		chargeAnimTrack:Stop()
		chargeAnimTrack = nil
	end
end

local function enableMovementBlock()
	ContextActionService:BindAction("BlockMovement", blockMovement, false,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space)
end

local function disableMovementBlock()
	ContextActionService:UnbindAction("BlockMovement")
end

local function isInAir()
	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Freefall
end

local animations = {
	FaJinDash45 = Instance.new("Animation"),
	FaJinDashVertical = Instance.new("Animation")
}
animations.FaJinDash45.AnimationId = "rbxassetid://89712170981245"
animations.FaJinDashVertical.AnimationId = "rbxassetid://89712170981245"

local function createGui()
	local existingGui = player.PlayerGui:FindFirstChild("FaJinGui")
	if existingGui then
		existingGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FaJinGui"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = player.PlayerGui

	local leftBarBG = Instance.new("Frame")
	leftBarBG.Name = "LeftEnergyBarBG"
	leftBarBG.Size = UDim2.new(0, 20, 0, 60)
	leftBarBG.Position = UDim2.new(0.01, 0, 0.85, 0)
	leftBarBG.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	leftBarBG.BorderSizePixel = 1
	leftBarBG.Parent = gui

	local leftBarFill = Instance.new("Frame")
	leftBarFill.Name = "LeftEnergyBarFill"
	leftBarFill.Size = UDim2.new(1, 0, 0, 0)
	leftBarFill.Position = UDim2.new(0, 0, 1, 0)
	leftBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	leftBarFill.BorderSizePixel = 0
	leftBarFill.AnchorPoint = Vector2.new(0, 1)
	leftBarFill.Parent = leftBarBG

	local leftPercentText = Instance.new("TextLabel")
	leftPercentText.Name = "LeftPercentText"
	leftPercentText.Size = UDim2.new(1, 0, 0, 18)
	leftPercentText.Position = UDim2.new(0, 0, 1, 2)
	leftPercentText.BackgroundTransparency = 1
	leftPercentText.TextColor3 = Color3.new(1, 1, 1)
	leftPercentText.TextStrokeTransparency = 0.5
	leftPercentText.TextScaled = true
	leftPercentText.Text = "0%"
	leftPercentText.Parent = leftBarBG

	local rightBarBG = Instance.new("Frame")
	rightBarBG.Name = "RightEnergyBarBG"
	rightBarBG.Size = UDim2.new(0, 20, 0, 60)
	rightBarBG.Position = UDim2.new(0.05, 0, 0.85, 0)
	rightBarBG.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	rightBarBG.BorderSizePixel = 1
	rightBarBG.Parent = gui

	local rightBarFill = Instance.new("Frame")
	rightBarFill.Name = "RightEnergyBarFill"
	rightBarFill.Size = UDim2.new(1, 0, 0, 0)
	rightBarFill.Position = UDim2.new(0, 0, 1, 0)
	rightBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	rightBarFill.BorderSizePixel = 0
	rightBarFill.AnchorPoint = Vector2.new(0, 1)
	rightBarFill.Parent = rightBarBG

	local rightPercentText = Instance.new("TextLabel")
	rightPercentText.Name = "RightPercentText"
	rightPercentText.Size = UDim2.new(1, 0, 0, 18)
	rightPercentText.Position = UDim2.new(0, 0, 1, 2)
	rightPercentText.BackgroundTransparency = 1
	rightPercentText.TextColor3 = Color3.new(1, 1, 1)
	rightPercentText.TextStrokeTransparency = 0.5
	rightPercentText.TextScaled = true
	rightPercentText.Text = "0%"
	rightPercentText.Parent = rightBarBG

	return gui, leftBarFill, rightBarFill, leftPercentText, rightPercentText
end

local gui, leftBarFill, rightBarFill, leftPercentText, rightPercentText = createGui()

local function updateGui()
	local leftRatio = math.clamp(leftEnergy / 50, 0, 1)
	local rightRatio = math.clamp(rightEnergy / 50, 0, 1)
	leftBarFill.Size = UDim2.new(1, 0, leftRatio, 0)
	leftPercentText.Text = math.floor(leftRatio * 100) .. "%"
	rightBarFill.Size = UDim2.new(1, 0, rightRatio, 0)
	rightPercentText.Text = math.floor(rightRatio * 100) .. "%"
end

local leftEmitters, rightEmitters = {}, {}
local auraEmitter = nil
local function updateParticles(leftEnergyVal, rightEnergyVal)
	local maxLeft = #leftEmitters
	local numLeftToEnable = leftEnergyVal > 0 and math.ceil(maxLeft * (leftEnergyVal / 50)) or 0
	for i = 1, maxLeft do
		if leftEmitters[i] then
			leftEmitters[i].Enabled = i <= numLeftToEnable
		end
	end
	local maxRight = #rightEmitters
	local numRightToEnable = rightEnergyVal > 0 and math.ceil(maxRight * (rightEnergyVal / 50)) or 0
	for i = 1, maxRight do
		if rightEmitters[i] then
			rightEmitters[i].Enabled = i <= numRightToEnable
		end
	end
end

local function updateAura(totalEnergy)
	if not auraEmitter then
		auraEmitter = Instance.new("ParticleEmitter")
		auraEmitter.Texture = "rbxassetid://243098098"
		auraEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		auraEmitter.Size = NumberSequence.new(0.3)
		auraEmitter.Lifetime = NumberRange.new(1)
		auraEmitter.Rate = 10
		auraEmitter.Speed = NumberRange.new(1)
		auraEmitter.SpreadAngle = Vector2.new(360, 360)
		auraEmitter.Parent = character:FindFirstChild("HumanoidRootPart")
	end
	auraEmitter.Enabled = totalEnergy > 0 and isFaJinActive
end

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	isFaJinActive = false
	leftEnergy = 0
	rightEnergy = 0
	leftEmitters = {}
	rightEmitters = {}
	if auraEmitter then
		auraEmitter:Destroy()
		auraEmitter = nil
	end
	gui, leftBarFill, rightBarFill, leftPercentText, rightPercentText = createGui()
end)

humanoid.Jumping:Connect(function()
	if not isFaJinActive then return end
	leftEnergy = math.clamp(leftEnergy + 1, 0, 50)
	rightEnergy = math.clamp(rightEnergy + 1, 0, 50)
	RemoteEvent:FireServer("UpdateEnergies", leftEnergy, rightEnergy)
	updateGui()
end)

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		pressedKeys[input.KeyCode] = true
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			controlPressed = true
		elseif input.KeyCode == Enum.KeyCode.Space and controlPressed and isFaJinActive then
			isCharging = true
			chargeStartTime = tick()
			lastUpdateTime = chargeStartTime
			playChargeAnimation()
			enableMovementBlock()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		pressedKeys[input.KeyCode] = nil
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			controlPressed = false
			if isCharging then
				isCharging = false
				stopChargeAnimation()
				disableMovementBlock()
				RemoteEvent:FireServer("UpdateEnergies", leftEnergy, rightEnergy)
			end
		end
	end
end)

local chargeConnection
chargeConnection = RunService.Heartbeat:Connect(function(deltaTime)
	if not isCharging then return end
	local currentTime = tick()
	local rate = 5
	leftEnergy = math.clamp(leftEnergy + rate * deltaTime, 0, 50)
	rightEnergy = math.clamp(rightEnergy + rate * deltaTime, 0, 50)
	updateGui()
	if currentTime - lastUpdateTime >= updateInterval then
		RemoteEvent:FireServer("UpdateEnergies", leftEnergy, rightEnergy)
		lastUpdateTime = currentTime
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.Three then
		local fullCowlState = character:FindFirstChild("FullCowlActive")
		if fullCowlState and fullCowlState.Value then
			RemoteEvent:FireServer("ToggleFaJin")
		else
			warn("Full Cowl deve estar ativo para usar o Fa Jin.")
		end
	elseif isFaJinActive and key == Enum.KeyCode.F then
		local currentTime = tick()
		local isMoving = pressedKeys[Enum.KeyCode.W] or pressedKeys[Enum.KeyCode.A] or pressedKeys[Enum.KeyCode.S] or pressedKeys[Enum.KeyCode.D]
		local skillName = isMoving and "FaJinDash45" or "FaJinDashVertical"
		if lastFPressedTime and currentTime - lastFPressedTime < 0.4 then
			if leftEnergy > 0 and rightEnergy > 0 then
				RemoteEvent:FireServer("Skill", skillName, "double")
			else
				lastFPressedTime = nil
			end
		else
			RemoteEvent:FireServer("Skill", skillName, "single")
			lastFPressedTime = currentTime
		end
	end
end)

RemoteEvent.OnClientEvent:Connect(function(action, value1, value2)
	if action == "UpdateEnergies" then
		leftEnergy = value1
		rightEnergy = value2
		updateGui()
		updateParticles(leftEnergy, rightEnergy)
		updateAura(leftEnergy + rightEnergy)
	elseif action == "Error" then
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(0.3, 0, 0.05, 0)
		errorLabel.Position = UDim2.new(0.35, 0, 0.75, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		errorLabel.Text = value1
		errorLabel.TextScaled = true
		errorLabel.Parent = gui
		local sound = ReplicatedStorage.FaJin:FindFirstChild("ErrorSound")
		if sound then
			sound:Play()
		end
		task.wait(2)
		errorLabel:Destroy()
	elseif action == "PlayAnimation" then
		local animation = animations[value1]
		if animation then
			local track = humanoid:LoadAnimation(animation)
			track:Play()
		else
			warn("Animation not found: " .. tostring(value1))
		end

	elseif action == "FaJinToggled" then
		isFaJinActive = value1
		gui.Enabled = isFaJinActive
		if isFaJinActive then
			leftEnergy = 0
			rightEnergy = 0
			local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg")
			local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightUpperLeg")
			if leftLeg and rightLeg then
				local leftFaJin = leftLeg:FindFirstChild("FaJinLeftLeg")
				local rightFaJin = rightLeg:FindFirstChild("FaJinRightLeg")
				if leftFaJin and rightFaJin then
					leftEmitters, rightEmitters = {}, {}
					for _, child in pairs(leftFaJin:GetDescendants()) do
						if child:IsA("ParticleEmitter") then
							table.insert(leftEmitters, child)
							child.Enabled = false
						end
					end
					for _, child in pairs(rightFaJin:GetDescendants()) do
						if child:IsA("ParticleEmitter") then
							table.insert(rightEmitters, child)
							child.Enabled = false
						end
					end
					updateParticles(leftEnergy, rightEnergy)
					updateAura(leftEnergy + rightEnergy)
				end
			end
		else
			leftEmitters, rightEmitters = {}, {}
			if auraEmitter then
				auraEmitter.Enabled = false
			end
			leftEnergy = 0
			rightEnergy = 0
			updateGui()
		end
	end
end)
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ofaFullCowlFolder = ReplicatedStorage:WaitForChild("OFAFullCowl")
local fullCowlEvent = ofaFullCowlFolder:WaitForChild("OFAFullCowl_RemoteEvent")
local fajinRemote = ReplicatedStorage:WaitForChild("FaJin"):WaitForChild("FaJinRemoteEvent")
local blackwhipRemote = ReplicatedStorage:WaitForChild("BlackWhip"):WaitForChild("BlackwhipRemoteEvent")
local floatRemote = ReplicatedStorage:WaitForChild("Float"):WaitForChild("FloatRemoteEvent")  -- Novo RemoteEvent para Float

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local fullCowlActive = false
local isFaJinActive = false
local isBlackwhipActive = false
local isFloatActive = false  -- Nova variável para Float
local isMoving = false -- Track movement state

local function createFullCowlState(char)
	local fullCowlState = char:FindFirstChild("FullCowlActive")
	if not fullCowlState then
		fullCowlState = Instance.new("BoolValue")
		fullCowlState.Name = "FullCowlActive"
		fullCowlState.Value = false
		fullCowlState.Parent = char
	end
	return fullCowlState
end

local fullCowlState = createFullCowlState(character)

-- GUI setup remains unchanged
local gui = Instance.new("ScreenGui")
gui.Name = "OFAStarsGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local starsFrame = Instance.new("Frame")
starsFrame.BackgroundTransparency = 1
starsFrame.AnchorPoint = Vector2.new(1, 1)
starsFrame.Position = UDim2.new(1, -10, 1, -10)
starsFrame.Size = UDim2.new(0.12, 0, 0.18, 0)
starsFrame.Parent = gui

local function createStar(name, color, pos)
	local star = Instance.new("Frame")
	star.Name = name
	star.AnchorPoint = Vector2.new(0.5, 0.5)
	star.Position = pos
	star.Size = UDim2.new(0.15, 0, 0.15, 0)
	star.BackgroundTransparency = 1
	star.Parent = starsFrame

	local diamond = Instance.new("Frame")
	diamond.Size = UDim2.new(1, 0, 1, 0)
	diamond.AnchorPoint = Vector2.new(0.5, 0.5)
	diamond.Position = UDim2.new(0.5, 0, 0.5, 0)
	diamond.BackgroundColor3 = color
	diamond.BorderSizePixel = 0
	diamond.BackgroundTransparency = 0.4
	diamond.Rotation = 45
	diamond.Name = "Outer"
	diamond.Parent = star

	local grad1 = Instance.new("UIGradient")
	grad1.Rotation = 45
	grad1.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
	}
	grad1.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)
	}
	grad1.Parent = diamond

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(0.5, 0, 0.5, 0)
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.BackgroundColor3 = color
	inner.BorderSizePixel = 0
	inner.BackgroundTransparency = 0.2
	inner.Rotation = 45
	inner.Name = "Inner"
	inner.Parent = star

	local grad2 = Instance.new("UIGradient")
	grad2.Rotation = 45
	grad2.Color = grad1.Color
	grad2.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)
	}
	grad2.Parent = inner

	return star
end

local stars = {
	White = createStar("WhiteStar", Color3.fromRGB(255, 255, 255), UDim2.new(0.50, 0, 0.50, 0)),
	Red = createStar("RedStar", Color3.fromRGB(255, 0, 0), UDim2.new(0.50, 0, 0.15, 0)),
	Green = createStar("GreenStar", Color3.fromRGB(0, 255, 0), UDim2.new(0.77, 0, 0.37, 0)),
	Blue = createStar("BlueStar", Color3.fromRGB(0, 128, 255), UDim2.new(0.23, 0, 0.37, 0)),
	Orange = createStar("OrangeStar", Color3.fromRGB(255, 128, 0), UDim2.new(0.77, 0, 0.67, 0)),
	Purple = createStar("PurpleStar", Color3.fromRGB(170, 0, 255), UDim2.new(0.23, 0, 0.67, 0)),
	Pink = createStar("PinkStar", Color3.fromRGB(255, 0, 170), UDim2.new(0.50, 0, 0.85, 0))
}

local function setStarTransparency(star, transparency)
	for _, obj in ipairs(star:GetChildren()) do
		if obj:IsA("Frame") then
			obj.BackgroundTransparency = transparency
		end
	end
end

local activeTweens = {}
local function pulseStar(star, active)
	if activeTweens[star] then
		activeTweens[star]:Cancel()
		activeTweens[star] = nil
	end
	if active then
		local tween = TweenService:Create(star, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Size = UDim2.new(0.18, 0, 0.18, 0)})
		tween:Play()
		activeTweens[star] = tween
	else
		star.Size = UDim2.new(0.15, 0, 0.15, 0)
	end
end

local function updateStars()
	for _, star in pairs(stars) do
		setStarTransparency(star, 0.5)
		pulseStar(star, false)
	end
	if fullCowlActive then
		setStarTransparency(stars.White, 0)
		pulseStar(stars.White, true)
	end
	if isFaJinActive then
		setStarTransparency(stars.Red, 0)
		pulseStar(stars.Red, true)
	end
	if isBlackwhipActive then
		setStarTransparency(stars.Orange, 0)
		pulseStar(stars.Orange, true)
	end
	if isFloatActive then
		setStarTransparency(stars.Pink, 0)
		pulseStar(stars.Pink, true)
	end
end

fajinRemote.OnClientEvent:Connect(function(action, value1)
	if action == "FaJinToggled" then
		isFaJinActive = value1
		updateStars()
	end
end)

blackwhipRemote.OnClientEvent:Connect(function(action, value1)
	if action == "BlackwhipToggled" then
		isBlackwhipActive = value1
		updateStars()
	end
end)

floatRemote.OnClientEvent:Connect(function(action, value1)
	if action == "FloatToggled" then
		isFloatActive = value1
		updateStars()
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	fullCowlActive = false
	isFaJinActive = false
	isBlackwhipActive = false
	isFloatActive = false
	isMoving = false
	fullCowlState = createFullCowlState(character)
	updateStars()
end)

-- Track movement input for animation control
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.W then
		isMoving = true
		if fullCowlActive then
			fullCowlEvent:FireServer("PlayWindup")
		end
	end
	if input.KeyCode == Enum.KeyCode.One then
		fullCowlActive = not fullCowlActive
		fullCowlState.Value = fullCowlActive
		fullCowlEvent:FireServer()
		if not fullCowlActive then
			if isFaJinActive then
				fajinRemote:FireServer("ToggleFaJin")
			end
			if isBlackwhipActive then
				blackwhipRemote:FireServer("ToggleBlackwhip")
			end
			if isFloatActive then
				floatRemote:FireServer("ToggleFloat")
			end
			isMoving = false
			fullCowlEvent:FireServer("StopWindup")
		end
		updateStars()
	end
	if input.KeyCode == Enum.KeyCode.LeftShift and fullCowlActive then
		fullCowlEvent:FireServer("ToggleSpeedBurst")
	end
	if input.KeyCode == Enum.KeyCode.Seven then  -- Tecla 7 para Float
		local fullCowlState = character:FindFirstChild("FullCowlActive")
		if fullCowlState and fullCowlState.Value then
			floatRemote:FireServer("ToggleFloat")
		else
			warn("Full Cowl deve estar ativo para usar o Float.")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.W then
		isMoving = false
		if fullCowlActive then
			fullCowlEvent:FireServer("StopWindup")
		end
	end
end)

updateStars()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ofaFullCowlFolder = ReplicatedStorage:WaitForChild("OFAFullCowl")
local fullCowlEvent = ofaFullCowlFolder:WaitForChild("OFAFullCowl_RemoteEvent")

local dummyCont = ofaFullCowlFolder:WaitForChild("Dummy CONT")
local dummyTemp = ofaFullCowlFolder:WaitForChild("Dummy TEMP")

local BUFF_CONFIG = {
	WalkSpeed = { Default = 16, Buffed = 75, TransitionTime = 5 },
	JumpPower = { Default = 50, Buffed = 75, TransitionTime = 5 }
}

local playerData = {}

local function isValidHumanoid(humanoid)
	return humanoid and humanoid.Parent and humanoid:IsA("Humanoid") and humanoid.Health > 0
end

local function ensureFullCowlActive(character)
	local fullCowlState = character:FindFirstChild("FullCowlActive")
	if not fullCowlState then
		fullCowlState = Instance.new("BoolValue")
		fullCowlState.Name = "FullCowlActive"
		fullCowlState.Value = false
		fullCowlState.Parent = character
		warn("BoolValue FullCowlActive criado para personagem: ", character)
	end
	return fullCowlState
end

local function applyBuffs(character, data)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not isValidHumanoid(humanoid) then
		warn("Humanoid inválido ou não encontrado: ", humanoid)
		return
	end

	data.DefaultWalkSpeed = humanoid.WalkSpeed or BUFF_CONFIG.WalkSpeed.Default
	data.DefaultJumpPower = humanoid.JumpPower or BUFF_CONFIG.JumpPower.Default

	local tweenInfo = TweenInfo.new(BUFF_CONFIG.WalkSpeed.TransitionTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

	local success, walkSpeedTween = pcall(function()
		return TweenService:Create(humanoid, tweenInfo, { WalkSpeed = BUFF_CONFIG.WalkSpeed.Buffed })
	end)
	if success then
		data.WalkSpeedTween = walkSpeedTween
		walkSpeedTween:Play()
	else
		humanoid.WalkSpeed = BUFF_CONFIG.WalkSpeed.Buffed
	end

	local success2, jumpPowerTween = pcall(function()
		return TweenService:Create(humanoid, tweenInfo, { JumpPower = BUFF_CONFIG.JumpPower.Buffed })
	end)
	if success2 then
		data.JumpPowerTween = jumpPowerTween
		jumpPowerTween:Play()
	else
		humanoid.JumpPower = BUFF_CONFIG.JumpPower.Buffed
	end
end

local function removeBuffs(character, data)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if isValidHumanoid(humanoid) and data.DefaultWalkSpeed and data.DefaultJumpPower then
		local tweenInfo = TweenInfo.new(BUFF_CONFIG.WalkSpeed.TransitionTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		if data.WalkSpeedTween then
			data.WalkSpeedTween:Cancel()
			data.WalkSpeedTween = nil
		end
		if data.JumpPowerTween then
			data.JumpPowerTween:Cancel()
			data.JumpPowerTween = nil
		end

		local walkBack = TweenService:Create(humanoid, tweenInfo, { WalkSpeed = data.DefaultWalkSpeed })
		local jumpBack = TweenService:Create(humanoid, tweenInfo, { JumpPower = data.DefaultJumpPower })

		walkBack:Play()
		jumpBack:Play()
	end
end

local function cloneAllFromDummy(dummyModel, character, isTemporary)
	local clones = {}

	for _, dummyPart in ipairs(dummyModel:GetChildren()) do
		if dummyPart:IsA("BasePart") then
			local charPart = character:FindFirstChild(dummyPart.Name)
			if charPart and charPart:IsA("BasePart") then
				for _, obj in ipairs(dummyPart:GetChildren()) do
					local ok, clone = pcall(function() return obj:Clone() end)
					if not ok or not clone then
						warn("Falha ao clonar objeto:", obj, "erro:", clone)
					else
						if clone:IsA("ParticleEmitter") or clone:IsA("Trail") or clone:IsA("Beam") then
							pcall(function() clone.Enabled = true end)
						end
						clone.Parent = charPart
						table.insert(clones, clone)

						if isTemporary then
							Debris:AddItem(clone, BUFF_CONFIG.WalkSpeed.TransitionTime)
						end
					end
				end
			else
				if #dummyPart:GetChildren() > 0 then
					warn("Parte correspondente não encontrada no personagem para clonar do dummy:", dummyPart.Name, "Personagem:", character.Name)
				end
			end
		end
	end

	return clones
end

local function clearClonesList(clones)
	if not clones then return end
	for _, c in ipairs(clones) do
		if c and c.Parent then
			if c:IsA("ParticleEmitter") or c:IsA("Trail") or c:IsA("Beam") then
				pcall(function() c.Enabled = false end)
			end
			pcall(function() c:Destroy() end)
		end
	end
end

local function addWalkEffects(data, char)
	if data.LeftLegPE then return end -- Already added

	local RS = game:GetService("ReplicatedStorage")
	local flashFolder = RS:FindFirstChild("Flash")
	if not flashFolder then
		warn("Flash folder not found in ReplicatedStorage")
		return
	end
	local walkFolder = flashFolder:FindFirstChild("Walk")
	if not walkFolder then
		warn("Walk folder not found in ReplicatedStorage.Flash")
		return
	end
	local particleEmitter = walkFolder:FindFirstChild("ParticleEmitter")
	local bbb = walkFolder:FindFirstChild("BBB")
	if not particleEmitter or not bbb then
		warn("ParticleEmitter or BBB not found in ReplicatedStorage.Flash.Walk")
		return
	end

	local leftLeg = char:FindFirstChild("Left Leg")
	local rightLeg = char:FindFirstChild("Right Leg")
	if not leftLeg or not rightLeg then
		warn("Left Leg or Right Leg not found in character:", char.Name)
		return
	end

	data.LeftLegPE = particleEmitter:Clone()
	data.LeftLegPE.Parent = leftLeg
	data.LeftLegBBB = bbb:Clone()
	data.LeftLegBBB.Parent = leftLeg

	data.RightLegPE = particleEmitter:Clone()
	data.RightLegPE.Parent = rightLeg
	data.RightLegBBB = bbb:Clone()
	data.RightLegBBB.Parent = rightLeg
end

local function clearWalkEffects(data, char)
	if data.LeftLegPE then
		if data.LeftLegPE.Parent then
			data.LeftLegPE:Destroy()
		end
		data.LeftLegPE = nil
	end
	if data.LeftLegBBB then
		if data.LeftLegBBB.Parent then
			data.LeftLegBBB:Destroy()
		end
		data.LeftLegBBB = nil
	end
	if data.RightLegPE then
		if data.RightLegPE.Parent then
			data.RightLegPE:Destroy()
		end
		data.RightLegPE = nil
	end
	if data.RightLegBBB then
		if data.RightLegBBB.Parent then
			data.RightLegBBB:Destroy()
		end
		data.RightLegBBB = nil
	end
	data.HasWalkEffects = false
end

local function activateFullCowl(player)
	local character = player.Character
	if not character then return end

	local uid = player.UserId
	local data = playerData[uid]
	if not data then
		data = {}
		playerData[uid] = data
	end

	if data.IsActivating or data.IsDeactivating then return end
	data.IsActivating = true

	data.FullCowlActive = true

	local fullCowlState = ensureFullCowlActive(character)
	fullCowlState.Value = false

	if data.TempClones then
		clearClonesList(data.TempClones)
		data.TempClones = nil
	end
	if data.ContClones then
		clearClonesList(data.ContClones)
		data.ContClones = nil
	end

	if dummyTemp then
		data.TempClones = cloneAllFromDummy(dummyTemp, character, true)
		warn("Efeitos temporários do Dummy TEMP aplicados para personagem:", character.Name)
	else
		warn("Modelo 'Dummy TEMP' não encontrado para emissores temporários")
	end

	applyBuffs(character, data)

	task.spawn(function()
		task.wait(BUFF_CONFIG.WalkSpeed.TransitionTime and 3 or 3)
		if dummyCont then
			data.ContClones = cloneAllFromDummy(dummyCont, character, false)
			warn("Efeitos contínuos do Dummy CONT aplicados para personagem:", character.Name)
		else
			warn("Modelo 'Dummy CONT' não encontrado para emissores contínuos")
		end

		task.wait(2)
		if data and data.IsActivating and character and character.Parent then
			data.IsFullCowlActive = true
			data.IsActivating = false
			fullCowlState.Value = true
			warn("FullCowlActive definido como true para personagem:", character.Name)
		else
			warn("Falha ao ativar FullCowlActive: personagem inválido ou cancelado")
			data.IsActivating = false
		end
	end)
end

local function deactivateSpeedBurst(player)
	local char = player.Character
	if not char then return end
	local humanoid = char.Humanoid
	local uid = player.UserId
	local data = playerData[uid] or {}
	playerData[uid] = data

	if not data.SpeedBurstActive then return end

	if data.MovementConnection then
		data.MovementConnection:Disconnect()
		data.MovementConnection = nil
	end

	-- Stop Windup animation and clear walk effects
	if data.WindupAnimation then
		data.WindupAnimation:Stop()
		data.WindupAnimation = nil
	end
	data.IsPlayingWindup = false
	clearWalkEffects(data, char)

	-- Use faster tween duration if FullCowl is off
	local targetSpeed = data.FullCowlActive and 75 or BUFF_CONFIG.WalkSpeed.Default
	local tweenDuration = data.FullCowlActive and 0.5 or 0.3 -- Faster decay (0.3s) when FullCowl is off
	local backTween = TweenService:Create(humanoid, TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {WalkSpeed = targetSpeed})
	backTween:Play()

	if data.Trail then
		data.Trail:Destroy()
		data.Trail = nil
	end

	data.SpeedBurstActive = false
	warn("SpeedBurst desativado para:", player.Name)
end

local function deactivateFullCowl(player)
	local character = player.Character
	if not character then return end

	local uid = player.UserId
	local data = playerData[uid]
	if not data then return end

	if data.IsActivating or data.IsDeactivating then return end
	data.IsDeactivating = true
	data.FullCowlActive = false

	local fullCowlState = character:FindFirstChild("FullCowlActive")
	if fullCowlState then
		fullCowlState.Value = false
	end

	if data.ContClones then
		clearClonesList(data.ContClones)
		data.ContClones = nil
	end
	if data.TempClones then
		clearClonesList(data.TempClones)
		data.TempClones = nil
	end

	-- Deactivate SpeedBurst if active, as if player toggled it off
	if data.SpeedBurstActive then
		deactivateSpeedBurst(player)
	end

	removeBuffs(character, data)

	data.IsDeactivating = false
	data.IsFullCowlActive = false
	warn("FullCowl desativado para:", player.Name)
end

local function resetStates(player)
	local uid = player.UserId
	local data = playerData[uid]
	if not data then return end

	if data.FullCowlActive then
		deactivateFullCowl(player)
	end
	if data.SpeedBurstActive then
		deactivateSpeedBurst(player)
	end

	data.FullCowlActive = false
	data.IsFullCowlActive = false
	data.SpeedBurstActive = false
	data.IsActivating = false
	data.IsDeactivating = false
	data.IsPlayingWindup = false

	if data.WalkSpeedTween then
		data.WalkSpeedTween:Cancel()
		data.WalkSpeedTween = nil
	end
	if data.JumpPowerTween then
		data.JumpPowerTween:Cancel()
		data.JumpPowerTween = nil
	end
	if data.ContClones then
		clearClonesList(data.ContClones)
		data.ContClones = nil
	end
	if data.TempClones then
		clearClonesList(data.TempClones)
		data.TempClones = nil
	end
	if data.Trail then
		data.Trail:Destroy()
		data.Trail = nil
	end
	if data.WindupAnimation then
		data.WindupAnimation:Stop()
		data.WindupAnimation = nil
	end

	local character = player.Character
	if character then
		clearWalkEffects(data, character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = BUFF_CONFIG.WalkSpeed.Default
			humanoid.JumpPower = BUFF_CONFIG.JumpPower.Default
		end
	end

	warn("Estados resetados para:", player.Name)
end

local function activateSpeedBurst(player)
	local RS = game:GetService("ReplicatedStorage")
	local TS = game:GetService("TweenService")
	local ofaFullCowl = ReplicatedStorage:WaitForChild("OFAFullCowl")

	local char = player.Character
	if not char then return end
	local humanoid = char.Humanoid
	local hrp = char.HumanoidRootPart

	local uid = player.UserId
	local data = playerData[uid] or {}
	playerData[uid] = data

	if data.SpeedBurstActive or not data.FullCowlActive then return end -- Prevent activation if Full Cowl is off

	local Stun = ofaFullCowl:WaitForChild("Stun"):Clone()
	local UnStun = ofaFullCowl:WaitForChild("UnStun"):Clone()

	Stun.Parent = char
	Stun.Enabled = true

	spawn(function()
		wait(0.7)
		Stun.Enabled = false
		UnStun.Parent = char
		UnStun.Enabled = true
	end)

	humanoid.WalkSpeed = 75

	local speedTween = TweenService:Create(humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {WalkSpeed = 325})
	speedTween:Play()

	local flashFolder = RS:FindFirstChild("Flash")
	if not flashFolder then
		warn("Flash folder not found in ReplicatedStorage")
		return
	end
	local trailAsset = flashFolder:FindFirstChild("Trail")
	if not trailAsset then
		warn("Trail not found in ReplicatedStorage.Flash")
		return
	end

	local existingTrail = char:FindFirstChild("Trail")
	if existingTrail then
		existingTrail:Destroy()
	end
	local Trail = trailAsset:Clone()
	Trail.Parent = char
	local we = Instance.new("Weld")
	we.Part0 = char.Torso
	we.Part1 = Trail
	we.Parent = Trail
	we.C0 = CFrame.new(0,0,0) * CFrame.Angles(0,math.rad(0),0)
	data.Trail = Trail

	data.SpeedBurstActive = true
	data.HasWalkEffects = false
	data.IsPlayingWindup = false
	warn("SpeedBurst ativado para:", player.Name)

	-- Movement-based effects and animation toggle
	data.MovementConnection = RunService.Heartbeat:Connect(function()
		if not char.Parent or not data.SpeedBurstActive then
			if data.MovementConnection then
				data.MovementConnection:Disconnect()
				data.MovementConnection = nil
			end
			if data.WindupAnimation then
				data.WindupAnimation:Stop()
				data.WindupAnimation = nil
			end
			data.IsPlayingWindup = false
			clearWalkEffects(data, char)
			return
		end

		local moving = (humanoid.MoveDirection.Magnitude > 0.01)
		if moving ~= data.HasWalkEffects then
			if moving then
				addWalkEffects(data, char)
				if not data.IsPlayingWindup then
					local windupAnim = ofaFullCowl:FindFirstChild("Windup")
					if windupAnim then
						data.WindupAnimation = humanoid:LoadAnimation(windupAnim)
						data.WindupAnimation:Play()
						data.IsPlayingWindup = true
					else
						warn("Windup animation not found in ReplicatedStorage.OFAFullCowl")
					end
				end
			else
				clearWalkEffects(data, char)
				if data.IsPlayingWindup then
					if data.WindupAnimation then
						data.WindupAnimation:Stop()
						data.WindupAnimation = nil
					end
					data.IsPlayingWindup = false
				end
			end
			data.HasWalkEffects = moving
		end
	end)

	speedTween.Completed:Wait()
end

local function playWindup(player)
	-- No-op: Windup animation is controlled exclusively by SpeedBurst movement
end

local function stopWindup(player)
	-- No-op: Windup animation is controlled exclusively by SpeedBurst movement
end

fullCowlEvent.OnServerEvent:Connect(function(player, action)
	if not player or not player.Character then return end
	local uid = player.UserId
	local data = playerData[uid]
	if not data then
		data = {}
		playerData[uid] = data
	end

	if action == "ToggleSpeedBurst" then
		if data.FullCowlActive then
			if data.SpeedBurstActive then
				deactivateSpeedBurst(player)
			else
				activateSpeedBurst(player)
			end
		end
	elseif action == "PlayWindup" then
		-- Ignore client-side PlayWindup event
	elseif action == "StopWindup" then
		-- Ignore client-side StopWindup event
	else
		if data.FullCowlActive then
			deactivateFullCowl(player)
		else
			activateFullCowl(player)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local uid = player.UserId
	local data = playerData[uid]
	if not data then return end

	if data.ContClones then
		clearClonesList(data.ContClones)
		data.ContClones = nil
	end
	if data.TempClones then
		clearClonesList(data.TempClones)
		data.TempClones = nil
	end
	if data.Trail then
		data.Trail:Destroy()
		data.Trail = nil
	end
	if data.MovementConnection then
		data.MovementConnection:Disconnect()
		data.MovementConnection = nil
	end
	if data.WindupAnimation then
		data.WindupAnimation:Stop()
		data.WindupAnimation = nil
	end
	data.IsPlayingWindup = false
	clearWalkEffects(data, player.Character)
	if data.WalkSpeedTween then
		pcall(function() data.WalkSpeedTween:Cancel() end)
		data.WalkSpeedTween = nil
	end
	if data.JumpPowerTween then
		pcall(function() data.JumpPowerTween:Cancel() end)
		data.JumpPowerTween = nil
	end
	playerData[uid] = nil
	warn("Dados do jogador limpos:", player.Name)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(char)
		resetStates(player)
	end)

	player.CharacterAdded:Connect(function(char)
		task.wait(1)
		resetStates(player)
	end)
end)
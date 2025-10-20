local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RemoteEvent = ReplicatedStorage.FaJin:WaitForChild("FaJinRemoteEvent")
local RagdollModule = require(ReplicatedStorage.OFA.Modules.Ragdoll)

local playerData = {}

local Skills = {
	["FaJinDash45"] = {
		execute = function(player, E_used, moveDirection)
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if not rootPart then
				warn("HumanoidRootPart not found for " .. player.Name)
				RemoteEvent:FireClient(player, "Error", "Invalid character")
				return
			end

			local direction
			if moveDirection and moveDirection.Magnitude > 0 then
				direction = (moveDirection + Vector3.new(0, 1, 0)).Unit
			else
				direction = (rootPart.CFrame.LookVector + Vector3.new(0, 1, 0)).Unit
			end

			local multiplier = 0.5 + (E_used / 100) * 1.5
			local velocity = Instance.new("BodyVelocity")
			velocity.MaxForce = Vector3.new(40000, 40000, 40000)
			velocity.Velocity = direction * (E_used * 7.2)
			velocity.Parent = rootPart
			Debris:AddItem(velocity, 0.5)

			local dashEffect = ReplicatedStorage.FaJin.FaJinEffects:FindFirstChild("FaJinDashOFA")
			if dashEffect then
				local clonedEffect = dashEffect:Clone()
				clonedEffect.Parent = game.Workspace.FX
				local position = rootPart.Position + direction * 5
				clonedEffect.CFrame = CFrame.new(position, position + direction) * CFrame.Angles(0, math.rad(-90), 0)
				if clonedEffect:IsA("BasePart") then
					clonedEffect.Size = clonedEffect.Size * 1.5
				elseif clonedEffect:IsA("Model") and clonedEffect:FindFirstChildWhichIsA("BasePart") then
					local primaryPart = clonedEffect:FindFirstChildWhichIsA("BasePart")
					if primaryPart then
						primaryPart.Size = primaryPart.Size * 1.5
					end
				end
				local particleEmitters = {}
				local maxLifetime = 0
				for _, child in pairs(clonedEffect:GetDescendants()) do
					if child:IsA("ParticleEmitter") then
						child.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.5, 0),
							NumberSequenceKeypoint.new(1, 1)
						})
						child.Rate = child.Rate * 3
						table.insert(particleEmitters, child)
						local lifetime = child.Lifetime.Max
						if lifetime > maxLifetime then
							maxLifetime = lifetime
						end
					end
				end
				for _, emitter in pairs(particleEmitters) do
					emitter.Enabled = true
				end
				task.wait(0.2)
				for _, emitter in pairs(particleEmitters) do
					emitter.Enabled = false
				end
				Debris:AddItem(clonedEffect, maxLifetime)
			end
			local dashSound = ReplicatedStorage.FaJin:FindFirstChild("DashSound")
			if dashSound then
				local clonedSound = dashSound:Clone()
				clonedSound.Parent = rootPart
				clonedSound:Play()
				Debris:AddItem(clonedSound, 2)
			end
			RemoteEvent:FireClient(player, "PlayAnimation", "FaJinDash45")
		end
	},
	["FaJinDashVertical"] = {
		execute = function(player, E_used)
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if not rootPart then
				warn("HumanoidRootPart not found for " .. player.Name)
				RemoteEvent:FireClient(player, "Error", "Invalid character")
				return
			end
			local direction = Vector3.new(0, 1, 0)
			local multiplier = 0.5 + (E_used / 100) * 1.5
			local velocity = Instance.new("BodyVelocity")
			velocity.MaxForce = Vector3.new(40000, 40000, 40000)
			velocity.Velocity = direction * (E_used * 7.2)
			velocity.Parent = rootPart
			Debris:AddItem(velocity, 0.5)
			local dashEffect = ReplicatedStorage.FaJin.FaJinEffects:FindFirstChild("FaJinDashOFA")
			if dashEffect then
				local clonedEffect = dashEffect:Clone()
				clonedEffect.Parent = game.Workspace.FX
				local position = rootPart.Position + direction * 5
				clonedEffect.CFrame = CFrame.new(position, position + direction) * CFrame.Angles(0, math.rad(-90), 0)
				if clonedEffect:IsA("BasePart") then
					clonedEffect.Size = clonedEffect.Size * 1.5
				elseif clonedEffect:IsA("Model") and clonedEffect:FindFirstChildWhichIsA("BasePart") then
					local primaryPart = clonedEffect:FindFirstChildWhichIsA("BasePart")
										if primaryPart then
						primaryPart.Size = primaryPart.Size * 1.5
					end
				end
				local particleEmitters = {}
				local maxLifetime = 0
				for _, child in pairs(clonedEffect:GetDescendants()) do
					if child:IsA("ParticleEmitter") then
						child.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.5, 0),
							NumberSequenceKeypoint.new(1, 1)
						})
						child.Rate = child.Rate * 3
						table.insert(particleEmitters, child)
						local lifetime = child.Lifetime.Max
						if lifetime > maxLifetime then
							maxLifetime = lifetime
						end
					end
				end
				for _, emitter in pairs(particleEmitters) do
					emitter.Enabled = true
				end
				task.wait(0.2)
				for _, emitter in pairs(particleEmitters) do
					emitter.Enabled = false
				end
				Debris:AddItem(clonedEffect, maxLifetime)
			end
			local dashSound = ReplicatedStorage.FaJin:FindFirstChild("DashSound")
			if dashSound then
				local clonedSound = dashSound:Clone()
				clonedSound.Parent = rootPart
				clonedSound:Play()
				Debris:AddItem(clonedSound, 2)
			end
			RemoteEvent:FireClient(player, "PlayAnimation", "FaJinDashVertical")
		end
	}
}

Players.PlayerAdded:Connect(function(player)
	playerData[player.UserId] = {
		LeftLeg = nil,
		RightLeg = nil,
		LeftEnergy = 0,
		RightEnergy = 0,
		LeftCoolDown = 0,
		RightCoolDown = 0,
		IsFaJinActive = false,
		PendingSingle = nil,
	}
	player.CharacterRemoving:Connect(function()
		local data = playerData[player.UserId]
		if data then
			if data.LeftLeg then data.LeftLeg:Destroy() end
			if data.RightLeg then data.RightLeg:Destroy() end
			data.IsFaJinActive = false
			data.LeftEnergy = 0
			data.RightEnergy = 0
			data.LeftLeg = nil
			data.RightLeg = nil
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player.UserId]
	if data then
		if data.LeftLeg then data.LeftLeg:Destroy() end
		if data.RightLeg then data.RightLeg:Destroy() end
		playerData[player.UserId] = nil
	end
end)

RemoteEvent.OnServerEvent:Connect(function(player, value, skillName, mode, moveDirection)
	if value == "ToggleFaJin" then
		local data = playerData[player.UserId]
		if not data then return end
		local character = player.Character
		if not character or not character.Parent then
			RemoteEvent:FireClient(player, "Error", "Character not found")
			return
		end
		if not data.IsFaJinActive then
			local leftLegPart = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
			local rightLegPart = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
			if not leftLegPart or not rightLegPart then
				RemoteEvent:FireClient(player, "Error", "Failed to activate FaJin: legs not found")
				return
			end
			local faJinFolder = ReplicatedStorage:FindFirstChild("FaJin")
			if not faJinFolder then
				RemoteEvent:FireClient(player, "Error", "FaJin folder not found")
				return
			end
			local leftLegModel = faJinFolder:FindFirstChild("LeftLeg")
			local rightLegModel = faJinFolder:FindFirstChild("RightLeg")
			if not leftLegModel or not rightLegModel then
				RemoteEvent:FireClient(player, "Error", "Leg models not found")
				return
			end
			local leftLeg = leftLegModel:Clone()
			leftLeg.Name = "FaJinLeftLeg"
			leftLeg.Parent = leftLegPart
			leftLeg.CFrame = leftLegPart.CFrame
			local rightLeg = rightLegModel:Clone()
			rightLeg.Name = "FaJinRightLeg"
			rightLeg.Parent = rightLegPart
			rightLeg.CFrame = rightLegPart.CFrame
			local weldLeft = Instance.new("WeldConstraint")
			weldLeft.Part0 = leftLeg
			weldLeft.Part1 = leftLegPart
			weldLeft.Parent = leftLegPart
			local weldRight = Instance.new("WeldConstraint")
			weldRight.Part0 = rightLeg
			weldRight.Part1 = rightLegPart
			weldRight.Parent = rightLegPart
			data.LeftLeg = leftLeg
			data.RightLeg = rightLeg
			data.IsFaJinActive = true
			data.LeftEnergy = 0
			data.RightEnergy = 0
			RemoteEvent:FireClient(player, "FaJinToggled", true)
			local sound = ReplicatedStorage.FaJin:FindFirstChild("EquipSound")
			if sound then
				local clonedSound = sound:Clone()
				clonedSound.Parent = character.HumanoidRootPart
				clonedSound:Play()
				Debris:AddItem(clonedSound, 2)
			end
		else
			data.IsFaJinActive = false
			data.LeftEnergy = 0
			data.RightEnergy = 0
			if data.LeftLeg then
				data.LeftLeg:Destroy()
				data.LeftLeg = nil
			end
			if data.RightLeg then
				data.RightLeg:Destroy()
				data.RightLeg = nil
			end
			RemoteEvent:FireClient(player, "FaJinToggled", false)
			local sound = ReplicatedStorage.FaJin:FindFirstChild("UnequipSound")
			if sound then
				local clonedSound = sound:Clone()
				clonedSound.Parent = character.HumanoidRootPart
				clonedSound:Play()
				Debris:AddItem(clonedSound, 2)
			end
		end
		RemoteEvent:FireClient(player, "UpdateEnergies", data.LeftEnergy, data.RightEnergy)
	elseif value == "UpdateEnergies" then
		local data = playerData[player.UserId]
		if data and data.IsFaJinActive then
			data.LeftEnergy = math.clamp(skillName or 0, 0, 50)
			data.RightEnergy = math.clamp(mode or 0, 0, 50)
			RemoteEvent:FireClient(player, "UpdateEnergies", data.LeftEnergy, data.RightEnergy)
		end
	elseif value == "Skill" then
		local data = playerData[player.UserId]
		if not data or not data.IsFaJinActive then
			RemoteEvent:FireClient(player, "Error", "FaJin disabled")
			return
		end
		if not Skills[skillName] then
			warn("Invalid skill received: " .. tostring(skillName))
			RemoteEvent:FireClient(player, "Error", "Invalid skill: " .. tostring(skillName))
			return
		end
		if skillName == "FaJinDash45" or skillName == "FaJinDashVertical" then
			if mode == "single" then
				data.PendingSingle = { SkillName = skillName, MoveDirection = moveDirection }
				task.delay(0.12, function()
					if data.PendingSingle and data.PendingSingle.SkillName == skillName then
						local legs_available = {}
						if data.LeftCoolDown < tick() and data.LeftEnergy > 0 then
							table.insert(legs_available, "left")
						end
						if data.RightCoolDown < tick() and data.RightEnergy > 0 then
							table.insert(legs_available, "right")
						end
						if #legs_available == 0 then
							RemoteEvent:FireClient(player, "Error", "No legs available")
							data.PendingSingle = nil
							return
						end
						local chosen_leg = #legs_available == 1 and legs_available[1] or (data.LeftEnergy > data.RightEnergy and "left" or "right")
						local E_used
						if chosen_leg == "left" then
							E_used = data.LeftEnergy
							data.LeftEnergy = 0
							data.LeftCoolDown = tick() + 0.2
						else
							E_used = data.RightEnergy
							data.RightEnergy = 0
							data.RightCoolDown = tick() + 0.2
						end
						Skills[skillName].execute(player, E_used, data.PendingSingle.MoveDirection)
						RemoteEvent:FireClient(player, "UpdateEnergies", data.LeftEnergy, data.RightEnergy)
						data.PendingSingle = nil
					end
				end)
			elseif mode == "double" then
				if data.PendingSingle then
					data.PendingSingle = nil
				end
				if data.LeftCoolDown < tick() and data.RightCoolDown < tick() and data.LeftEnergy > 0 and data.RightEnergy > 0 then
					local E_used = data.LeftEnergy + data.RightEnergy
					data.LeftEnergy = 0
					data.RightEnergy = 0
					data.LeftCoolDown = tick() + 0.2
					data.RightCoolDown = tick() + 0.2
					Skills[skillName].execute(player, E_used, moveDirection)
					RemoteEvent:FireClient(player, "UpdateEnergies", data.LeftEnergy, data.RightEnergy)
				else
					RemoteEvent:FireClient(player, "Error", "Both legs must be available")
				end
			else
				warn("Invalid mode for skill: " .. tostring(mode))
				RemoteEvent:FireClient(player, "Error", "Invalid mode: " .. tostring(mode))
			end
		end
	end
end)
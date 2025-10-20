local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local RemoteEvent = ReplicatedStorage:WaitForChild("BlackWhip"):WaitForChild("BlackwhipRemoteEvent")
local Folder = ReplicatedStorage:WaitForChild("BlackWhip")

local playerData = {}

Players.PlayerAdded:Connect(function(player)
	playerData[player.UserId] = {
		IsBlackwhipActive = false,
		Cooldowns = {},
		ActiveLassos = {}
	}
	player.CharacterRemoving:Connect(function()
		local data = playerData[player.UserId]
		if data then
			for side, lassoData in pairs(data.ActiveLassos) do
				if lassoData.lasso then lassoData.lasso:Destroy() end
				if lassoData.beam then lassoData.beam:Destroy() end
				if lassoData.originAttachment then lassoData.originAttachment:Destroy() end
				if lassoData.endAttachment then lassoData.endAttachment:Destroy() end
				if lassoData.connection then lassoData.connection:Disconnect() end
				if lassoData.touchedConn then lassoData.touchedConn:Disconnect() end
				if lassoData.target and lassoData.pull then
					lassoData.pull:Destroy()
					lassoData.target.WalkSpeed = lassoData.originalWalkSpeed or 16
					lassoData.target.JumpPower = lassoData.originalJumpPower or 50
					lassoData.target.AutoRotate = lassoData.originalAutoRotate or true
					lassoData.target.PlatformStand = lassoData.originalPlatformStand or false
					lassoData.target:ChangeState(Enum.HumanoidStateType.Running)
					if lassoData.animatorDestroyed then
						Instance.new("Animator", lassoData.target)
					end
					if lassoData.torsoWrapped then
						local otherSide = side == "Left" and "Right" or "Left"
						local other = data.ActiveLassos[otherSide]
						if not other or other.target ~= lassoData.target then
							lassoData.torsoWrapped:Destroy()
						end
					end
				end
			end
			data.ActiveLassos = {}
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player.UserId]
	if data then
		for side, lassoData in pairs(data.ActiveLassos) do
			if lassoData.lasso then lassoData.lasso:Destroy() end
			if lassoData.beam then lassoData.beam:Destroy() end
			if lassoData.originAttachment then lassoData.originAttachment:Destroy() end
			if lassoData.endAttachment then lassoData.endAttachment:Destroy() end
			if lassoData.connection then lassoData.connection:Disconnect() end
			if lassoData.touchedConn then lassoData.touchedConn:Disconnect() end
			if lassoData.target and lassoData.pull then
				lassoData.pull:Destroy()
				lassoData.target.WalkSpeed = lassoData.originalWalkSpeed or 16
				lassoData.target.JumpPower = lassoData.originalJumpPower or 50
				lassoData.target.AutoRotate = lassoData.originalAutoRotate or true
				lassoData.target.PlatformStand = lassoData.originalPlatformStand or false
				lassoData.target:ChangeState(Enum.HumanoidStateType.Running)
				if lassoData.animatorDestroyed then
					Instance.new("Animator", lassoData.target)
				end
				if lassoData.torsoWrapped then
					local otherSide = side == "Left" and "Right" or "Left"
					local other = data.ActiveLassos[otherSide]
					if not other or other.target ~= lassoData.target then
						lassoData.torsoWrapped:Destroy()
					end
				end
			end
		end
		playerData[player.UserId] = nil
	end
end)

RemoteEvent.OnServerEvent:Connect(function(player, action, ...)
	local data = playerData[player.UserId]
	if not data then
		warn("Player data not found for: ", player.Name)
		return
	end
	print("Server: Recebido do jogador", player.Name, ":", action)

	if action == "ToggleBlackwhip" then
		data.IsBlackwhipActive = not data.IsBlackwhipActive
		print("Server: Enviando BlackwhipToggled para", player.Name, "com estado", data.IsBlackwhipActive)
		RemoteEvent:FireClient(player, "BlackwhipToggled", data.IsBlackwhipActive)

		if not data.IsBlackwhipActive then
			for side, lassoData in pairs(data.ActiveLassos) do
				if lassoData.lasso then lassoData.lasso:Destroy() end
				if lassoData.beam then lassoData.beam:Destroy() end
				if lassoData.originAttachment then lassoData.originAttachment:Destroy() end
				if lassoData.endAttachment then lassoData.endAttachment:Destroy() end
				if lassoData.connection then lassoData.connection:Disconnect() end
				if lassoData.touchedConn then lassoData.touchedConn:Disconnect() end
				if lassoData.target and lassoData.pull then
					lassoData.pull:Destroy()
					lassoData.target.WalkSpeed = lassoData.originalWalkSpeed or 16
					lassoData.target.JumpPower = lassoData.originalJumpPower or 50
					lassoData.target.AutoRotate = lassoData.originalAutoRotate or true
					lassoData.target.PlatformStand = lassoData.originalPlatformStand or false
					lassoData.target:ChangeState(Enum.HumanoidStateType.Running)
					if lassoData.animatorDestroyed then
						Instance.new("Animator", lassoData.target)
					end
					if lassoData.torsoWrapped then
						local otherSide = side == "Left" and "Right" or "Left"
						local other = data.ActiveLassos[otherSide]
						if not other or other.target ~= lassoData.target then
							lassoData.torsoWrapped:Destroy()
						end
					end
				end
			end
			data.ActiveLassos = {}
		end

	elseif action == "UseBlackwhip" then
		local target, side, isActive = ...
		if not data.IsBlackwhipActive then
			warn("Blackwhip is not active for player: ", player.Name)
			return
		end
		if not player or not side then return end
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local hand = (side == "Left" and (char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")))
			or (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
		if not hand then return end

		if not isActive then
			if data.ActiveLassos[side] then
				local lassoData = data.ActiveLassos[side]
				if lassoData.lasso then lassoData.lasso:Destroy() end
				if lassoData.beam then lassoData.beam:Destroy() end
				if lassoData.originAttachment then lassoData.originAttachment:Destroy() end
				if lassoData.endAttachment then lassoData.endAttachment:Destroy() end
				if lassoData.connection then lassoData.connection:Disconnect() end
				if lassoData.touchedConn then lassoData.touchedConn:Disconnect() end
				if lassoData.pull then lassoData.pull:Destroy() end
				if lassoData.target then
					lassoData.target.WalkSpeed = lassoData.originalWalkSpeed or 16
					lassoData.target.JumpPower = lassoData.originalJumpPower or 50
					lassoData.target.AutoRotate = lassoData.originalAutoRotate or true
					lassoData.target.PlatformStand = lassoData.originalPlatformStand or false
					lassoData.target:ChangeState(Enum.HumanoidStateType.Running)
					if lassoData.animatorDestroyed then
						Instance.new("Animator", lassoData.target)
					end
					if lassoData.torsoWrapped then
						local otherSide = side == "Left" and "Right" or "Left"
						local other = data.ActiveLassos[otherSide]
						if not other or other.target ~= lassoData.target then
							lassoData.torsoWrapped:Destroy()
						end
					end
				end
				data.ActiveLassos[side] = nil
			end
			return
		end

		if not target or not target.Parent or target.Health <= 0 then return end
		local targetHRP = target.Parent:FindFirstChild("HumanoidRootPart")
		if not targetHRP then return end

		if data.ActiveLassos[side] then return end

		data.Cooldowns[side] = data.Cooldowns[side] or 0
		if tick() - data.Cooldowns[side] < 1 then return end
		data.Cooldowns[side] = tick()

		local origin = hand.Position
		local dir = (targetHRP.Position - origin).Unit
		local distance = (targetHRP.Position - origin).Magnitude
		local maxDist = 200
		if distance > maxDist then
			distance = maxDist
		end

		local template = Folder:FindFirstChild("BlackWhip")
		if not template then
			warn("BlackWhip template not found")
			return
		end

		local lasso = template:Clone()
		lasso.Parent = workspace
		lasso.CanCollide = false
		lasso.Anchored = false
		lasso.CFrame = CFrame.new(origin + dir * 0.1)

		local originAttachment = lasso:FindFirstChild("Beam1")
		local endAttachment = lasso:FindFirstChild("Beam2")
		if not (originAttachment and endAttachment) then
			warn("Attachments Beam1 or Beam2 not found in BlackWhip")
			lasso:Destroy()
			return
		end

		originAttachment.Parent = hand
		originAttachment.WorldCFrame = hand.CFrame

		local speed = 100
		local beam = lasso:FindFirstChildOfClass("Beam")
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = dir * speed
		bv.Parent = lasso

		local lassoData = {
			lasso = lasso,
			beam = beam,
			originAttachment = originAttachment,
			endAttachment = endAttachment,
			target = target,
			originalWalkSpeed = target.WalkSpeed,
			originalJumpPower = target.JumpPower,
			originalAutoRotate = target.AutoRotate,
			originalPlatformStand = target.PlatformStand,
			animatorDestroyed = false,
			torsoWrapped = nil,
			createdWrapped = false,
			connection = nil,
			touchedConn = nil,
			pull = nil
		}
		data.ActiveLassos[side] = lassoData

		local beamHit = false
		local touchedConn
		touchedConn = lasso.Touched:Connect(function(hit)
			if beamHit then return end
			if hit:IsDescendantOf(target.Parent) then
				beamHit = true
				bv:Destroy()
				local upperTorso = target.Parent:FindFirstChild("UpperTorso") or target.Parent:FindFirstChild("Torso")
				if not upperTorso then
					lasso:Destroy()
					if originAttachment then originAttachment:Destroy() end
					if endAttachment then endAttachment:Destroy() end
					if touchedConn then touchedConn:Disconnect() end
					data.ActiveLassos[side] = nil
					return
				end
				local torsoWrapped = upperTorso:FindFirstChild("Torso Wrapped")
				local created = false
				if not torsoWrapped then
					torsoWrapped = Folder:FindFirstChild("Torso Wrapped"):Clone()
					if torsoWrapped:IsA("BasePart") then
						torsoWrapped.CFrame = upperTorso.CFrame
						torsoWrapped.Anchored = false
						torsoWrapped.CanCollide = false
						torsoWrapped.Transparency = 1
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = upperTorso
						weld.Part1 = torsoWrapped
						weld.Parent = upperTorso
					end
					torsoWrapped.Parent = upperTorso
					created = true
				end
				lassoData.torsoWrapped = torsoWrapped
				lassoData.createdWrapped = created
				local beam12 = torsoWrapped:FindFirstChild("Beam12")
				local beam22 = torsoWrapped:FindFirstChild("Beam22")
				if not (beam12 and beam22) then
					warn("Attachments Beam12 or Beam22 not found in Torso Wrapped")
					lasso:Destroy()
					if originAttachment then originAttachment:Destroy() end
					if endAttachment then endAttachment:Destroy() end
					if touchedConn then touchedConn:Disconnect() end
					data.ActiveLassos[side] = nil
					return
				end
				local dir_to_player = (hrp.Position - upperTorso.Position).Unit
				local target_facing = upperTorso.CFrame.LookVector
				local chosenAttachment = if target_facing:Dot(dir_to_player) > 0 then beam22 else beam12
				beam.Attachment1 = chosenAttachment
				local delta = hand.Position - chosenAttachment.WorldPosition
				local verticalFactor = math.clamp(delta.Y / delta.Magnitude, -1, 1)
				local curveStrength = verticalFactor * 25
				beam.CurveSize0 = -curveStrength
				beam.CurveSize1 = curveStrength
				beam.Parent = workspace
				lasso:Destroy()
				lassoData.lasso = nil
				endAttachment:Destroy()
				lassoData.endAttachment = nil
				target.WalkSpeed = 0
				target.JumpPower = 0
				target.AutoRotate = false
				target.PlatformStand = true
				local animator = target:FindFirstChildOfClass("Animator")
				if animator then
					animator:Destroy()
					lassoData.animatorDestroyed = true
				end
				local vfxTemplate = ReplicatedStorage.BlackWhip:FindFirstChild("LightningVfx")
				if vfxTemplate then
					local vfx = vfxTemplate:Clone()
					vfx.Parent = targetHRP
					Debris:AddItem(vfx, 2)
				end
				local pull = Instance.new("BodyPosition")
				pull.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				pull.P = 12500
				pull.D = 1250
				pull.Parent = targetHRP
				lassoData.pull = pull
			end
		end)
		lassoData.touchedConn = touchedConn

		local connection
		connection = RunService.Heartbeat:Connect(function()
			if not data.ActiveLassos[side] then
				connection:Disconnect()
				return
			end

			originAttachment.WorldCFrame = hand.CFrame

			if not beamHit then
				if lasso.Parent then
					bv.Velocity = (targetHRP.Position - lasso.Position).Unit * speed
					if (lasso.Position - hand.Position).Magnitude >= distance or (targetHRP.Position - hand.Position).Magnitude > maxDist then
						lasso:Destroy()
						if originAttachment then originAttachment:Destroy() end
						if endAttachment then endAttachment:Destroy() end
						if touchedConn then touchedConn:Disconnect() end
						data.ActiveLassos[side] = nil
						connection:Disconnect()
					end
				end
			end

			if beamHit and lassoData.target then
				local dist = (targetHRP.Position - hrp.Position).Magnitude
				if dist > maxDist then
					if lassoData.beam then lassoData.beam:Destroy() end
					if lassoData.originAttachment then lassoData.originAttachment:Destroy() end
					if lassoData.pull then lassoData.pull:Destroy() end
					if lassoData.torsoWrapped then
						local otherSide = side == "Left" and "Right" or "Left"
						local other = data.ActiveLassos[otherSide]
						if not other or other.target ~= lassoData.target then
							lassoData.torsoWrapped:Destroy()
						end
					end
					if lassoData.target then
						lassoData.target.WalkSpeed = lassoData.originalWalkSpeed or 16
						lassoData.target.JumpPower = lassoData.originalJumpPower or 50
						lassoData.target.AutoRotate = lassoData.originalAutoRotate or true
						lassoData.target.PlatformStand = lassoData.originalPlatformStand or false
						lassoData.target:ChangeState(Enum.HumanoidStateType.Running)
						if lassoData.animatorDestroyed then
							Instance.new("Animator", lassoData.target)
						end
					end
					data.ActiveLassos[side] = nil
					connection:Disconnect()
					return
				end
				local currentDir = (targetHRP.Position - hrp.Position).Unit
				lassoData.pull.Position = hrp.Position + currentDir * 3
				local delta = hand.Position - lassoData.beam.Attachment1.WorldPosition
				local verticalFactor = math.clamp(delta.Y / delta.Magnitude, -1, 1)
				local curveStrength = verticalFactor * 25
				lassoData.beam.CurveSize0 = -curveStrength
				lassoData.beam.CurveSize1 = curveStrength
			end
		end)
		lassoData.connection = connection
	end
end)
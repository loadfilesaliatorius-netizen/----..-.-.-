-- ServerScript: FloatQuirkServer
-- Gerencia toggle de Float e orientação com BodyGyro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RemoteEvent = ReplicatedStorage:WaitForChild("Float"):WaitForChild("FloatRemoteEvent")
local playerData = {}
Players.PlayerAdded:Connect(function(player)
	playerData[player.UserId] = {
		IsFloatActive = false,
		Gyro = nil
	}
	player.CharacterRemoving:Connect(function()
		local data = playerData[player.UserId]
		if data then
			if data.Gyro then
				data.Gyro:Destroy()
				data.Gyro = nil
			end
			data.IsFloatActive = false
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	local data = playerData[player.UserId]
	if data then
		if data.Gyro then
			data.Gyro:Destroy()
		end
		playerData[player.UserId] = nil
	end
end)
RemoteEvent.OnServerEvent:Connect(function(player, action, ...)
	local data = playerData[player.UserId]
	if not data then return end
	local character = player.Character
	if not character or not character.Parent then
		RemoteEvent:FireClient(player, "Error", "Character not found")
		return
	end
	if action == "ToggleFloat" then
		data.IsFloatActive = not data.IsFloatActive
		RemoteEvent:FireClient(player, "FloatToggled", data.IsFloatActive)
		if not data.IsFloatActive then
			if data.Gyro then
				data.Gyro:Destroy()
				data.Gyro = nil
			end
		end
	elseif action == "UpdateOrientation" then
		local cameraCFrame, isFloating, onlyYAxis = ...
		if data.IsFloatActive and isFloating then
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			if not data.Gyro then
				data.Gyro = Instance.new("BodyGyro")
				data.Gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				data.Gyro.P = 10000
				data.Gyro.CFrame = root.CFrame
				data.Gyro.Parent = root
			end
			local lookDirection = cameraCFrame.LookVector
			local targetPosition = root.Position + lookDirection
			local targetCFrame
			if onlyYAxis then
				local currentY = root.Position.Y
				targetCFrame = CFrame.new(root.Position, Vector3.new(targetPosition.X, currentY, targetPosition.Z))
			else
				targetCFrame = CFrame.new(root.Position, targetPosition)
			end
			data.Gyro.CFrame = targetCFrame
		else
			if data.Gyro then
				data.Gyro:Destroy()
				data.Gyro = nil
			end
		end
	end
end)
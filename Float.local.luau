-- LocalScript: FloatQuirk (Float + Independent WASD Cooldowns + Physics Impulses + Reliable Toggle)
-- Física de levitação natural, com impulsos realistas e cooldown independente em cada direção.
-- Toggle via RemoteEvent (ativado pela tecla 7 no OFAFullCowl). Sem partículas. Mantém altura mínima de 5 studs do chão.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FloatFolder = ReplicatedStorage:WaitForChild("Float")
local AnimationsFolder = FloatFolder:WaitForChild("Animations")  -- Nova referência à pasta no ReplicatedStorage.Float
local RemoteEvent = FloatFolder:WaitForChild("FloatRemoteEvent")
local VerticalSpeed = 20 -- velocidade vertical (Space/Ctrl)
local ImpulseStrength = 25 -- força de cada impulso direcional
local ImpulseDamping = 0.9 -- dissipação natural da inércia
local InitialLift = 5 -- impulso inicial ao ativar no chão
local MinHoverHeight = 5 -- altura mínima do solo (em studs)
local ImpulseCooldown = 1.5 -- tempo entre impulsos por direção (segundos)
-- Estado
local walkspeed = humanoid.WalkSpeed
local floating = false
local landing = false
local impulseVector = Vector3.new(0, 0, 0)
-- Cooldown individual (cada direção com tempo separado)
local lastImpulse = {
	W = 0,
	A = 0,
	S = 0,
	D = 0
}
-- Animações
local floatingAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Floating"))
floatingAnim.Priority = Enum.AnimationPriority.Action
floatingAnim.Looped = true
local LandingAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Land"))
local RightAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Right")); RightAnim.Looped = true
local LeftAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Left")); LeftAnim.Looped = true
local FrontAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Forward")); FrontAnim.Looped = true
local BackAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Backward")); BackAnim.Looped = true
-- Parar todas as animações
local function stopAllAnimations()
	floatingAnim:Stop()
	LandingAnim:Stop()
	RightAnim:Stop()
	LeftAnim:Stop()
	FrontAnim:Stop()
	BackAnim:Stop()
end
-- Cria attachment se não existir
local function GetAttachment()
	local attach = root:FindFirstChild("FlyAttachment")
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "FlyAttachment"
		attach.Parent = root
	end
	return attach
end
-- Cria LinearVelocity se não existir
local function GetVelocity()
	local attach = GetAttachment()
	local velocity = attach:FindFirstChild("FlyVelocity")
	if not velocity then
		velocity = Instance.new("LinearVelocity")
		velocity.Name = "FlyVelocity"
		velocity.Parent = attach
		velocity.Attachment0 = attach
		velocity.MaxForce = 30000  -- Reduzido para permitir que BodyVelocity do Fajin (40000) domine no ar
	end
	return velocity
end
-- Distância do chão
local function getDistanceFromFloor()
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character}
	local result = workspace:Raycast(root.Position, Vector3.new(0, -100, 0), rayParams)
	if result then
		return (root.Position - result.Position).Magnitude, result
	else
		return 99999, nil
	end
end
-- Verifica se está no chão
local function isPlayerOnFloor()
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local size = Vector3.new(4, 0.2, 4)
	local pos = root.Position - Vector3.new(0, root.Size.Y / 2 + 0.1, 0)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(pos), size, params)
	for _, part in pairs(parts) do
		if part and part.CanCollide then
			return true
		end
	end
	return false
end
-- INICIA FLOAT (melhorado)
local function StartFloating()
	-- animações
	stopAllAnimations()
	if not floatingAnim.IsPlaying then
		floatingAnim:Play()
	end
	-- velocity
	local velocity = GetVelocity()
	velocity.MaxForce = 30000  -- Reduzido para sinergia com Fajin
	-- herda inércia horizontal e dá pequeno impulso vertical se estiver no chão
	if isPlayerOnFloor() then
		velocity.VectorVelocity = Vector3.new(root.AssemblyLinearVelocity.X, InitialLift, root.AssemblyLinearVelocity.Z)
	else
		velocity.VectorVelocity = Vector3.new(root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z) -- Preserve full, including vertical from Fajin
	end
	-- estados
	floating = true
	landing = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0  -- Desativa pulo
end
-- POUSAR IMEDIATO (melhorado)
local function ImmediateLanding()
	-- animações de pouso
	stopAllAnimations()
	if not LandingAnim.IsPlaying then
		LandingAnim:Play()
	end
	-- limpa attachment e velocity
	local attach = root:FindFirstChild("FlyAttachment")
	if attach then
		attach:Destroy()
	end
	-- restaura estados
	floating = false
	landing = false
	humanoid.WalkSpeed = walkspeed
	humanoid.JumpPower = 50  -- Restaura pulo padrão
end
-- Listener para toggle do servidor
RemoteEvent.OnClientEvent:Connect(function(action, value1)
	if action == "FloatToggled" then
		if value1 then
			StartFloating()
		else
			ImmediateLanding()
		end
	end
end)
-- Impulsos com cooldown individual (W/A/S/D)
uis.InputBegan:Connect(function(input, gameProcessed)
	-- Não processa se UI consumida
	if gameProcessed then return end
	-- Só processa teclas se estiver em float
	if not floating then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local key = input.KeyCode
	local now = tick()
	local dir = nil
	local camCF = workspace.CurrentCamera.CFrame
	local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
	local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
	-- Cada tecla com seu próprio cooldown
	if key == Enum.KeyCode.W and now - lastImpulse.W >= ImpulseCooldown then
		lastImpulse.W = now
		dir = forward
		FrontAnim:Play()
	elseif key == Enum.KeyCode.S and now - lastImpulse.S >= ImpulseCooldown then
		lastImpulse.S = now
		dir = -forward
		BackAnim:Play()
	elseif key == Enum.KeyCode.A and now - lastImpulse.A >= ImpulseCooldown then
		lastImpulse.A = now
		dir = -right
		LeftAnim:Play()
	elseif key == Enum.KeyCode.D and now - lastImpulse.D >= ImpulseCooldown then
		lastImpulse.D = now
		dir = right
		RightAnim:Play()
	end
	if dir then
		impulseVector = impulseVector + dir * ImpulseStrength
	end
end)
-- Para parar animações direcionais quando soltar
uis.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode == Enum.KeyCode.W then FrontAnim:Stop() end
	if input.KeyCode == Enum.KeyCode.S then BackAnim:Stop() end
	if input.KeyCode == Enum.KeyCode.A then LeftAnim:Stop() end
	if input.KeyCode == Enum.KeyCode.D then RightAnim:Stop() end
end)
-- Loop principal
RunService.RenderStepped:Connect(function(deltaTime)
	if floating then
		local velocity = GetVelocity()
		-- Gravidade reduzida (simula sustentação no ar)
		local GRAVITY_FACTOR = 0.2
		local currentVel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(
			currentVel.X,
			currentVel.Y - workspace.Gravity * GRAVITY_FACTOR * deltaTime,  -- Subtrai gravidade reduzida para preservar upward momentum
			currentVel.Z
		)
		-- Movimento vertical manual
		local verticalMove = 0
		if uis:IsKeyDown(Enum.KeyCode.Space) then
			verticalMove = VerticalSpeed
		elseif uis:IsKeyDown(Enum.KeyCode.LeftControl) then
			verticalMove = -VerticalSpeed
		end
		-- Mantém altura mínima de MinHoverHeight
		local floorDist, floorPoint = getDistanceFromFloor()
		if floorDist < MinHoverHeight and floorPoint then
			local correction = (MinHoverHeight - floorDist)
			root.CFrame = root.CFrame + Vector3.new(0, correction, 0)
			if verticalMove < 0 then verticalMove = 0 end
		end
		-- Dissipação natural do impulso (aplicada só aos impulsos internos)
		impulseVector = impulseVector * ImpulseDamping
		-- Preserva velocidades externas fully (currentVel includes external)
		local targetVel = Vector3(
			currentVel.X + impulseVector.X,
			currentVel.Y + verticalMove,
			currentVel.Z + impulseVector.Z
		)
		velocity.VectorVelocity = targetVel  -- Set direto, no Lerp, to preserve external fully
		-- Assegura que a animação de base esteja ativa
		if not floatingAnim.IsPlaying then
			floatingAnim:Play()
		end
	end
end)
-- Reset em CharacterAdded
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	floating = false
	-- Recarrega animações do ReplicatedStorage
	floatingAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Floating"))
	LandingAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Land"))
	RightAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Right")); RightAnim.Looped = true
	LeftAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Left")); LeftAnim.Looped = true
	FrontAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Forward")); FrontAnim.Looped = true
	BackAnim = humanoid:LoadAnimation(AnimationsFolder:WaitForChild("Backward")); BackAnim.Looped = true
end)
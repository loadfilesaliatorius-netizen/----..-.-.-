local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RagdollModule = require(ReplicatedStorage.OFA.Modules.Ragdoll)
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local PlayersHit = {}
local Cooldown = 5
local lastUseTime = {}

-- Configurações
local damage = 50
local pushForce = 100

local RemoteEvent = ReplicatedStorage.OFA:WaitForChild("OFA_RemoteEvent")

RemoteEvent.OnServerEvent:Connect(function(plr)
	if not plr then
		warn("Jogador é nulo no evento OnServerEvent")
		return
	end
	if lastUseTime[plr] and tick() - lastUseTime[plr] < Cooldown then
		warn("Habilidade em cooldown para " .. plr.Name)
		return
	end
	lastUseTime[plr] = tick()
	print("Habilidade Detroit Smash usada por " .. plr.Name)

	local char = plr.Character
	if not char then
		warn("Personagem é nulo para " .. plr.Name)
		return
	end
	local hum = char:WaitForChild("Humanoid")

	-- Guarda os valores originais
	local originalWalkSpeed = hum.WalkSpeed
	local originalJumpHeight = hum.JumpHeight

	-- Deixa o personagem completamente imóvel
	hum.WalkSpeed = 0
	hum.JumpHeight = 0
	hum.AutoRotate = false

	-- Efeitos de partículas
	local sp1 = ReplicatedStorage.OFA.Effects.ELECTRIC:Clone()
	local sp2 = ReplicatedStorage.OFA.Effects.ELECTRIC2:Clone()
	sp1.Parent = char["Right Arm"]
	sp2.Parent = char["Right Arm"]

	local PunchSound2 = ReplicatedStorage.OFA.Effects.sound:Clone()
	PunchSound2.Parent = char.HumanoidRootPart
	PunchSound2:Play()

	-- Destaque do braço (removido efeito vermelho)
	local Plrhighlight2 = Instance.new("Highlight")
	Plrhighlight2.Parent = char["Right Arm"]
	Plrhighlight2.DepthMode = Enum.HighlightDepthMode.Occluded
	Plrhighlight2.FillTransparency = 1 -- completamente transparente
	Plrhighlight2.OutlineTransparency = 1
	Debris:AddItem(Plrhighlight2, 3)

	task.wait(1.7)

	local PunchSound = ReplicatedStorage.OFA.Effects.Punch:Clone()
	PunchSound.Parent = char.HumanoidRootPart
	PunchSound:Play()
	Debris:AddItem(PunchSound, 4)

	hum.AutoRotate = false

	-- Dispara evento para clientes
	RemoteEvent:FireAllClients(plr)

	-- Slashes
	local Slash1 = ReplicatedStorage.OFA.Effects.Slash1:Clone()
	Slash1.Parent = workspace.FX
	Slash1.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
	Debris:AddItem(Slash1, 1.2)

	local Slash2 = ReplicatedStorage.OFA.Effects.Slash2:Clone()
	Slash2.Parent = workspace.FX
	Slash2.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 5, 6) * CFrame.Angles(math.rad(180), 0, 0)
	Debris:AddItem(Slash2, 2)

	local MoveInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	TweenService:Create(Slash1, MoveInfo, {CFrame = Slash1.CFrame * CFrame.new(0, 0, -150)}):Play()
	TweenService:Create(Slash1, MoveInfo, {Size = Vector3.new(75, 30.107, 8.611)}):Play()

	-- Efeitos de rochas e rubble
	-- (Mantidos como no original, sem alterações visuais de corpo)

	Slash1.Touched:Connect(function(hit)
		if not hit or not hit.Parent or not hit.Parent:FindFirstChild("Humanoid") or hit.Parent == plr.Character then
			return
		end
		if PlayersHit[hit.Parent] == nil then
			PlayersHit[hit.Parent] = true
			local enemyhum = hit.Parent:WaitForChild("Humanoid")

			enemyhum:TakeDamage(damage)

			hit.Parent.HumanoidRootPart.CFrame = CFrame.lookAt(hit.Parent.HumanoidRootPart.Position, plr.Character.HumanoidRootPart.Position)

			local vel = Instance.new("BodyVelocity", hit.Parent.HumanoidRootPart)
			vel.MaxForce = Vector3.new(1,1,1) * 1000000
			vel.Velocity = plr.Character.HumanoidRootPart.CFrame.LookVector * pushForce
			vel.Name = "SmallMoveVel"
			Debris:AddItem(vel, 0.4)

			RagdollModule.RagDoll(hit.Parent, 1)

			task.wait(1)

			-- Restaurando valores originais do usuário
			hum.WalkSpeed = originalWalkSpeed
			hum.JumpHeight = originalJumpHeight

			task.wait(3)
			PlayersHit[hit.Parent] = nil
		end
	end)

	-- Após finalização da habilidade, restaurar totalmente
	task.wait(0.5)
	hum.WalkSpeed = originalWalkSpeed
	hum.JumpHeight = originalJumpHeight
	hum.AutoRotate = true

	task.wait(0.4)
	sp1.Enabled = false
	sp2.Enabled = false
	sp1:Destroy()
	sp2:Destroy()
	for _, v in pairs(Slash2:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end
	end
end)

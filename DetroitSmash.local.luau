local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Configurações
local Cooldown = 5
local ActivationKey = Enum.KeyCode.Z

-- Referência ao RemoteEvent
local RemoteEvent = ReplicatedStorage.OFA:WaitForChild("OFA_RemoteEvent")

-- Referências ao personagem e humanoid
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Função para carregar animação
local function loadAnimation()
	local Anim = Instance.new("Animation")
	Anim.AnimationId = "rbxassetid://104012504756546"
	return humanoid:LoadAnimation(Anim)
end

-- Carrega a animação inicialmente
local AnimationTrack = loadAnimation()

-- Referência ao ShakeScript
local ShakeScriptTemplate = script.Parent:WaitForChild("DetroitSmash.ShakeScript")

-- Variável de debounce
local debounce = false

-- Atualiza referências ao renascer
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	AnimationTrack = loadAnimation()
	debounce = false
end)

-- Detecta pressionamento da tecla
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == ActivationKey then
		local fullCowlState = character:FindFirstChild("FullCowlActive")
		if not fullCowlState or not fullCowlState.Value then
			warn("Full Cowl deve estar ativo para usar Detroit Smash.")
			return
		end
		if not debounce then
			debounce = true
			print("Habilidade Detroit Smash disparada por " .. player.Name)
			RemoteEvent:FireServer()
			AnimationTrack:Play()
			task.wait(Cooldown)
			debounce = false
			print("Cooldown de Detroit Smash terminado para " .. player.Name)
		else
			warn("Habilidade em cooldown para " .. player.Name)
		end
	end
end)

-- Evento para efeitos do cliente (blur + shake)
RemoteEvent.OnClientEvent:Connect(function()
	game.Lighting.BlurEffect.Size = 20
	TweenService:Create(
		game.Lighting.BlurEffect,
		TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
		{Size = 0}
	):Play()

	local shakeScript = ShakeScriptTemplate:Clone()
	shakeScript.Parent = character
	shakeScript.Disabled = false
	Debris:AddItem(shakeScript, 2)
end)

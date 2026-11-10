local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local TOOL_DISPLAY_NAME = "Rainbow Gravity Coil" 
local HOLDING_GRAVITY = 80         
local RAINBOW_SPEED = 0.5            
local BUTTON_RAINBOW_SPEED = 0.2   
local TOGGLE_GUI_KEY = Enum.KeyCode.V
local NORMAL_GRAVITY = 196.2 

local COIL_MESH_ID = "rbxassetid://16606212"
local COIL_TEXTURE_ID = "rbxassetid://16606141"  
local GRAVITY_COIL_SOUND = "rbxassetid://16619553"

local currentTrail = nil
local attachment0 = nil
local attachment1 = nil
local syncConnection = nil
local guiRainbowConnection = nil
local monitorConnection = nil

local rainbowColorSequence = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 127, 0)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 255))
})

local function createTrail(character)
	if currentTrail then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 1, 0)
	attachment0.Parent = rootPart
	
	attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, -2, 0)
	attachment1.Parent = rootPart
	
	currentTrail = Instance.new("Trail")
	currentTrail.Attachment0 = attachment0
	currentTrail.Attachment1 = attachment1
	
	currentTrail.Lifetime = 0.45
	currentTrail.WidthScale = NumberSequence.new(0.4, 0)   
	currentTrail.Transparency = NumberSequence.new(0, 0.4) 

	currentTrail.Parent = rootPart
end

local function removeTrail()
	if currentTrail then currentTrail:Destroy(); currentTrail = nil end
	if attachment0 then attachment0:Destroy(); attachment0 = nil end
	if attachment1 then attachment1:Destroy(); attachment1 = nil end
end

local function setupToolEvents(tool, handle, particles)
	tool.Equipped:Connect(function()
		workspace.Gravity = HOLDING_GRAVITY 
		particles.Enabled = true            
		
		local character = tool.Parent
		if character then
			createTrail(character)
			
			local head = character:FindFirstChild("Head")
			if head then
				local equipSound = Instance.new("Sound")
				equipSound.Name = "CoilEquipSound"
				equipSound.SoundId = GRAVITY_COIL_SOUND
				equipSound.Volume = 0.7 
				equipSound.Pitch = 1.0  
				equipSound.Parent = head
				
				equipSound:Play()
				equipSound.Ended:Connect(function()
					equipSound:Destroy()
				end)
			end
		end
		
		if syncConnection then syncConnection:Disconnect() end
		syncConnection = RunService.RenderStepped:Connect(function()
			local hue = (tick() * RAINBOW_SPEED) % 1
			local currentRainbowColor = Color3.fromHSV(hue, 1, 1)
			local currentSequence = ColorSequence.new(currentRainbowColor)
			
			handle.Color = currentRainbowColor
			particles.Color = currentSequence
			if currentTrail then
				currentTrail.Color = currentSequence
			end
		end)
	end)

	tool.Unequipped:Connect(function()
		workspace.Gravity = NORMAL_GRAVITY  
		particles.Enabled = false
		removeTrail()
		
		if syncConnection then syncConnection:Disconnect(); syncConnection = nil end
		
		local character = LocalPlayer.Character
		if character and character:FindFirstChild("Head") then
			local oldSound = character.Head:FindFirstChild("CoilEquipSound")
			if oldSound then oldSound:Destroy() end
		end
	end)

	tool.Destroying:Connect(function()
		workspace.Gravity = NORMAL_GRAVITY
		removeTrail()
		if syncConnection then syncConnection:Disconnect(); syncConnection = nil end
	end)
end

local function hasTool()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local character = LocalPlayer.Character
	local inBackpack = backpack and backpack:FindFirstChild(TOOL_DISPLAY_NAME)
	local inHand = character and character:FindFirstChild(TOOL_DISPLAY_NAME)
	return (inBackpack or inHand)
end

local function createGravityTool()
	if hasTool() then return end

	local newTool = Instance.new("Tool")
	newTool.Name = TOOL_DISPLAY_NAME
	newTool.RequiresHandle = true
	
	local newHandle = Instance.new("Part")
	newHandle.Name = "Handle"
	newHandle.Size = Vector3.new(1, 1, 1)   
	newHandle.Material = Enum.Material.Neon 
	newHandle.Parent = newTool
	
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = COIL_MESH_ID
	mesh.Scale = Vector3.new(0.75, 0.75, 0.75) 
	mesh.Parent = newHandle
	
	local newParticles = Instance.new("ParticleEmitter")
	newParticles.Name = "GlowParticles"
	newParticles.Lifetime = NumberRange.new(1, 1.5)
	newParticles.Speed = NumberRange.new(2, 5)
	newParticles.Size = NumberSequence.new(0.18, 0) 
	newParticles.Enabled = false
	newParticles.Parent = newHandle
	
	setupToolEvents(newTool, newHandle, newParticles)
	newTool.Parent = LocalPlayer:FindFirstChild("Backpack")
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecGravityGui"
screenGui.ResetOnSpawn = false 

local success, _ = pcall(function() screenGui.Parent = CoreGui end)
if not success then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local textButton = Instance.new("TextButton")
textButton.Name = "GetButton"
textButton.Size = UDim2.new(0, 100, 0, 50)
textButton.Position = UDim2.new(0.85, 0, 0.75, 0) 
textButton.Text = "Get"
textButton.TextColor3 = Color3.fromRGB(255, 255, 255) 
textButton.TextSize = 24
textButton.Font = Enum.Font.SourceSansBold
textButton.Active = true
textButton.Draggable = true
textButton.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = textButton

guiRainbowConnection = RunService.RenderStepped:Connect(function()
	local hue = (tick() * BUTTON_RAINBOW_SPEED) % 1
	textButton.BackgroundColor3 = Color3.fromHSV(hue, 0.7, 0.9)
end)

textButton.MouseButton1Click:Connect(function()
	createGravityTool()
end)

monitorConnection = RunService.Heartbeat:Connect(function()
	if hasTool() then
		textButton.Visible = false
	else
		textButton.Visible = true
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == TOGGLE_GUI_KEY then
		textButton.Visible = not textButton.Visible
	end
end)

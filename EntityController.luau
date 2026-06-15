local EntityController = {} 
EntityController.__index = EntityController

type Modes = "Attack"| "Chaser" | "Wanderer" | "Useless"

function EntityController.new(entity : Humanoid, behavior : Modes)
	local self = setmetatable({}, EntityController)

	entity:SetAttribute("Behavior", behavior)
	self.Name = nil
	self.entity = entity
	self.Behavior = self.entity:GetAttribute("Behavior")
	self.Parent = entity.Parent
	self.Running = false

	return self
end

--These functions  are for Manually Changing things and properties


--Normal functions for the entity

--Plays the animation

function EntityController:PlayAnimation(animation : Animation, wantLooped : boolean, priority : Enum.AnimationPriority)
	local Animator = self.entity:FindFirstChild("Animator")
	local AnimaTrack = Animator:LoadAnimation(animation)
	if wantLooped then
		AnimaTrack.Looped = true
	end
	AnimaTrack.Priority = priority
	AnimaTrack:Play()
end

--Stops the animation

function EntityController:StopAnimation(animation : Animation)
	local Animator = self.entity:FindFirstChild("Animator")
	local AnimaTrack = Animator:FindFirstChildOfClass("AnimationTrack")
	AnimaTrack:Stop()
end

--Sets Name of the entity

function EntityController:SetName(name : string)
	self.Name = name
	self.entity.DisplayName = name
	print("Successfull Name Set")
end

--Change the behavior of the entity

function EntityController:ChangeBehavior(behavior : Modes)
	self.Behavior = behavior	
	self.entity:SetAttribute("Behavior", behavior)
	print("Succesfull Behavior Change")
end

--Destroys the entity

function EntityController:Destroy()
	if self.entity then
		self.entity:Destroy()
	end
	setmetatable(self, nil)
	table.clear(self)

	print("Successful Destroy")
end

--Sets or Changes Attribute Value

function EntityController:SetOrChangeAttribute(attribute :string, Value: any)
	self.entity:SetAttribute(attribute, Value)
end

--Gets Attribute Value

function EntityController:GetAttribute(attribute :string)
	return self.entity:GetAttribute(attribute)
end

--Makes him Die

function EntityController:Die()
	self.entity.Health = 0 
	self.entity:Destroy()
	print("Entity Died")
end

--Gives Damage to the entity

function EntityController:TakeDamage(Value)
	if self.entity.Health > 0 then 
		self.entity:TakeDamage(Value)
	end
end

--Heals the entity

function EntityController:Heal(Value)
	if self.entity.Health > 0 then 
		self.entity.Health += Value
	end
end

--Changes WalkSpeed	

function EntityController:ChangeSpeed(Value)
	self.entity.WalkSpeed = Value
end

--Changes Jump Power

function EntityController:ChangeJumpPower(Value)
	self.entity.JumpPower = Value
end

--Changes Jump Height

function EntityController:ChangeJumpHeight(Value)
	self.entity.JumpHeight = Value
end

--Gets Health Percentage

function EntityController:GetHealthPercent()
	return (self.entity.Health / self.entity.MaxHealth) * 100
end

--Changes MaxHealth

function EntityController:SetMaxHealth(value)
	self.entity.MaxHealth = value
	self.entity.Health = math.min(self.entity.Health, value)
end

--Functions Only for Behavior type "Attack" and "Chaser"

function EntityController:FindNearestEnemy(maxdistance : number)
	if self.Behavior == "Attack" or self.Behavior == "Chaser" then
		local OwnCharacter = self.Parent
		local OwnHumanoidRootPart = OwnCharacter:FindFirstChild("HumanoidRootPart")

		local PlayersInRange = {}
		local Players = game:GetService("Players")

		for _, player in pairs(Players:GetPlayers()) do
			local Character = player.Character or player.CharacterAdded:Wait()
			if Character then
				local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
				if HumanoidRootPart then
					local distance = (HumanoidRootPart.Position - OwnHumanoidRootPart.Position).Magnitude
					if distance <= maxdistance then
						table.insert(PlayersInRange, {player, distance})
					end
				end
			end
		end

		table.sort(PlayersInRange, function(a,b)
			return a[2] < b[2]
		end)

		if #PlayersInRange > 0 then
			return PlayersInRange[1][1]
		else
			return nil
		end


	else
		print("Wrong Behavior Type")
	end
end

--Function for all Behaviors except "Useless"

function EntityController:Roam(vectors : Vector3)
	self.entity:MoveTo(vectors)
end

--function for Behavior type "Attack"

function EntityController:Attack(damageValue : number)
	if self.Behavior == "Attack" then

		local OwnCharacter = self.Parent
		local OwnHumanoidRootPart = OwnCharacter:FindFirstChild("HumanoidRootPart")
		local player = self:FindNearestEnemy(50)

		if not player then return end 

		local Humanoid = player.Character:FindFirstChild("Humanoid")
		local HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
		local rayacastParams = RaycastParams.new()
		rayacastParams.FilterType = Enum.RaycastFilterType.Exclude
		rayacastParams.FilterDescendantsInstances = {self.Parent}

		local direction = (HumanoidRootPart.Position - OwnHumanoidRootPart.Position).Unit * 4

		local raycastResult = workspace:Raycast(OwnHumanoidRootPart.Position, direction , rayacastParams)

		if raycastResult then
			local hitpart = raycastResult.Instance
			if hitpart then
				local Character = hitpart.Parent
				if Character then
					local humanoid = Character:FindFirstChild("Humanoid")
					if humanoid then
						local player = game:GetService("Players"):GetPlayerFromCharacter(Character)
						if player then
							humanoid:TakeDamage(damageValue)
						end
					end
				end
			end
		else
			print("Nothing!")
		end
	end
end

--function for Behavior type "Chaser" and "Attack"

function EntityController:MoveToPlayer(player)
	local Character = player.Character or player.CharacterAdded:Wait()
	if Character then
		local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local OwnCharacter = self.Parent
			local OwnHumanoidRootPart = OwnCharacter:FindFirstChild("HumanoidRootPart")
			OwnHumanoidRootPart.Rotation = humanoidRootPart.Rotation
			self:Roam(humanoidRootPart.Position + Vector3.new(0,0,3))
		end
	end
end

--function for Behavior type "Wanderer"

function EntityController:RoamAround(target: BasePart, radius: number)
	local randomX = math.random(-radius, radius)
	local randomZ = math.random(-radius, radius)

	local destination = target.Position + Vector3.new(randomX, 0, randomZ)

	self.entity:MoveTo(destination)
end

--End of Manual Functions

--Automatic Functions

function EntityController:Start()
	if self.Running then return end
	self.Running = true

	task.spawn(function()
		while self.Running and self.entity and self.entity.Health > 0 do

			if self.Behavior == "Attack" then
				local player = self:FindNearestEnemy(45)
				if player then
					self:MoveToPlayer(player)
					self:Attack(8)
				end

			elseif self.Behavior == "Wanderer" then
				self:RoamAround(workspace.SpawnLocation, 50)

			elseif self.Behavior == "Chaser" then
				local player = self:FindNearestEnemy(45)
				if player then
					self:MoveToPlayer(player)
				end
			end

			task.wait(1)
		end
	end)
end

function EntityController:Stop()
	self.Running = false
end


return EntityController


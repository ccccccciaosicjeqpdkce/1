local MODULES = {}
local ENEMIES = {}

getgenv().config = {
    kill = {
        gun = false,
        knife = false
    },
    lock = {
        gun = false,
        knife = false
    }
}

local gun = "Gun_Equip"
local knife = "Knife_Equip"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

function MODULES:EquipWeapon(weapon)
    local player = Players.LocalPlayer
    local backpack = player.Backpack
    local character = player.Character
    if not character or not backpack then return false end

    for _, tool in pairs(backpack:GetChildren()) do
        if tool:GetAttribute("EquipAnimation") == weapon then
            character.Humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end

-- GUN CONTROLLER
function MODULES:ExecuteGunController()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local camera = Workspace.CurrentCamera
    local Tags = require(ReplicatedStorage.Modules.Tags)
    local Maid = require(ReplicatedStorage.Modules.Util.Maid).new()
    local WeaponRaycast = require(ReplicatedStorage.Modules.WeaponRaycast)
    local CollisionGroups = require(ReplicatedStorage.Modules.CollisionGroups)
    local CharacterRayOrigin = require(ReplicatedStorage.Modules.CharacterRayOrigin)
    local BulletRenderer = require(ReplicatedStorage.Modules.BulletRenderer)
    local ShootGun = ReplicatedStorage.Remotes.ShootGun
    local lastShot

    character.ChildAdded:Connect(function(tool)
        if not tool:IsA("Tool") or not CollectionService:HasTag(tool, Tags.GUN_TOOL) then return end
        Maid:DoCleaning()
        Maid:GiveTask(tool.AncestryChanged:Connect(function()
            if not tool:IsDescendantOf(character) then
                Maid:DoCleaning()
            end
        end))

        local cooldown = tool:GetAttribute("Cooldown")
        local function canShoot() return not lastShot or os.clock() - lastShot >= (cooldown or 0) end
        local function onActivated(target)
            if not canShoot() then return end
            local muzzle = tool:FindFirstChild("Muzzle", true)
            if not muzzle then return warn("No Muzzle in "..tool.Name) end
            lastShot = os.clock()
            target = target or (player:GetMouse().Hit.Position + player:GetMouse().UnitRay.Direction * 50)
            local origin = CharacterRayOrigin(character)
            if not origin then return end
            local hit = WeaponRaycast(origin, target)
            if tool:FindFirstChild("Fire") then tool.Fire:Play() end
            BulletRenderer(muzzle.WorldPosition, target, tool:GetAttribute("BulletType"))
            tool:Activate()
            ShootGun:FireServer(origin, target, hit and hit.Instance, hit and hit.Position)
        end

        Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
                onActivated()
            end
        end))
        Maid:GiveTask(UserInputService.TouchTapInWorld:Connect(function(pos, gp)
            if gp then return end
            onActivated(WeaponRaycast.convertScreenPointToVector3(pos, 2000))
        end))
    end)
end

function MODULES:DeleteGunController()
    local player = Players.LocalPlayer
    local gc1 = player:FindFirstChild("GunController")
    if gc1 then gc1:Destroy() end
    local hc = ReplicatedStorage:FindFirstChild("HiddenCharacters")
    if hc then
        local hcPlayer = hc:FindFirstChild(player.Name)
        local gc2 = hcPlayer and hcPlayer:FindFirstChild("GunController")
        if gc2 then gc2:Destroy() end
    end
end

-- KILL FUNCTIONS
function MODULES:KillAllKnife()
    if getgenv().config.lock.knife then return end
    MODULES:EquipWeapon(knife)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, part in pairs(ENEMIES) do
        task.spawn(function()
            if part then
                ReplicatedStorage.Remotes.ThrowStart:FireServer(hrp.Position, (part.Position - hrp.Position).Unit)
                ReplicatedStorage.Remotes.ThrowHit:FireServer(part, part.Position)
            end
        end)
    end
end

function MODULES:KillAllGun()
    if getgenv().config.lock.gun then return end
    MODULES:EquipWeapon(gun)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, part in pairs(ENEMIES) do
        task.spawn(function()
            if part then
                ReplicatedStorage.Remotes.ShootGun:FireServer(hrp.Position, part.Position, part, part.Position)
            end
        end)
    end
end

-- UPDATE ENEMIES
function MODULES:updateEnemies()
    for _, enemy in pairs(Players:GetPlayers()) do
        if enemy ~= Players.LocalPlayer and enemy.Team ~= Players.LocalPlayer.Team then
            local character = enemy.Character
            if character and character.Parent == Workspace then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then ENEMIES[enemy] = hrp end
            end
        end
    end
end

-- MAIN START FUNCTION
function MODULES:start()
    -- Update enemies periodically without blocking
    task.spawn(function()
        while task.wait(0.25) do
            if Players.LocalPlayer.Character then
                MODULES:updateEnemies()
            end
        end
    end)

    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        getgenv().config.lock.gun = true
        getgenv().config.lock.knife = true
        if getgenv().killing_loops.gun then MODULES:EquipWeapon(gun)
        elseif getgenv().killing_loops.knife then MODULES:EquipWeapon(knife) end

        local hrp = character:WaitForChild("HumanoidRootPart", 3)
        if not hrp or not Players.LocalPlayer:GetAttribute("Match") then return end

        local anchoredConn
        anchoredConn = hrp:GetPropertyChangedSignal("Anchored"):Connect(function()
            if not hrp.Anchored then
                if getgenv().killing_loops.gun then getgenv().config.lock.gun = false
                elseif getgenv().killing_loops.knife then getgenv().config.lock.knife = false end
                if anchoredConn then anchoredConn:Disconnect() end
            end
        end)
    end)
end

return MODULES

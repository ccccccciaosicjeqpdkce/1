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

function MODULES:ExecuteGunController()
    -- function's script not made by me, fully decompiled from roblox
    -- execute this once
    do
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CollectionService = game:GetService("CollectionService")
        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local ws = game:GetService("Workspace")                                                   -- added by me

        local Parent = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() -- editted
        local Player = Players.LocalPlayer
        local Mouse = Player:GetMouse()
        local Camera = ws.CurrentCamera -- editted

        local Tags = require(ReplicatedStorage.Modules.Tags)
        local Maid = require(ReplicatedStorage.Modules.Util.Maid).new()
        local WeaponRaycast = require(ReplicatedStorage.Modules.WeaponRaycast)
        local CollisionGroups = require(ReplicatedStorage.Modules.CollisionGroups)
        local CharacterRayOrigin = require(ReplicatedStorage.Modules.CharacterRayOrigin)
        local BulletRenderer = require(ReplicatedStorage.Modules.BulletRenderer)

        local ShootGun = ReplicatedStorage.Remotes.ShootGun

        local lastShot

        Parent.ChildAdded:Connect(function(tool)
            if not tool:IsA("Tool") then return end
            if not CollectionService:HasTag(tool, Tags.GUN_TOOL) then return end

            Maid:DoCleaning()

            Maid:GiveTask(tool.AncestryChanged:Connect(function()
                if not tool:IsDescendantOf(Parent) then
                    Maid:DoCleaning()
                end
            end))

            local Cooldown = tool:GetAttribute("Cooldown")

            local function canShoot()
                if not lastShot then return true end
                return os.clock() - lastShot >= (Cooldown or 0)
            end

            local function onActivated(target)
                if not canShoot() then return end

                local Muzzle = tool:FindFirstChild("Muzzle", true)
                if not Muzzle then
                    warn("Muzzle attachment not found for : " .. tool.Name)
                    return
                end

                lastShot = os.clock()

                if not target then
                    target = Mouse.Hit.Position + Mouse.UnitRay.Direction * 50
                end

                local screenHit = WeaponRaycast(
                    Camera.CFrame.Position,
                    target,
                    nil,
                    CollisionGroups.SCREEN_RAYCAST
                )

                local origin = CharacterRayOrigin(Parent)
                if not origin then return end

                local hit = WeaponRaycast(origin, target)

                local Fire = tool:FindFirstChild("Fire")
                if Fire then Fire:Play() end

                BulletRenderer(Muzzle.WorldPosition, target, tool:GetAttribute("BulletType"))
                tool:Activate()

                local hitInstance = hit and hit.Instance
                local hitPosition = hit and hit.Position

                ShootGun:FireServer(origin, target, hitInstance, hitPosition)
            end

            Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.KeyCode == Enum.KeyCode.ButtonR2 then
                    onActivated()
                end
            end))

            Maid:GiveTask(UserInputService.TouchTapInWorld:Connect(function(pos, gp)
                if gp then return end
                onActivated(WeaponRaycast.convertScreenPointToVector3(pos, 2000))
            end))
            Players.LocalPlayer.CharacterAdded:Connect(function(c)
                Parent = c
            end)
        end)
    end
end

function MODULES:DeleteGunController()
    -- execute this every time you respawn
    do
        local players = game:GetService("Players")
        local rs = game:GetService("ReplicatedStorage")

        local me = players.LocalPlayer
        local gc1 = me:FindFirstChild("GunController")

        if gc1 then gc1:Destroy() end

        local hc = rs:FindFirstChild("HiddenCharacters")
        if hc then
            local hc = hc:FindFirstChild(me.Name)
            local gc2 = hc and hc:FindFirstChild("GunController")
            if gc2 then
                gc2:Destroy()
            end
        end
    end
end

function MODULES:EquipWeapon(weapon)
    --[[ support weapons
    gun - Gun_Equip
    knife - Knife_Equip
    ]]

    do
        local players = game:GetService("Players")

        local backpack = players.LocalPlayer.Backpack
        local character = players.LocalPlayer.Character
        if not character or not backpack then
            return false
        end
        local a = 0

        while a < 10 do
            task.wait(0.25)
            a = a + 1
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:GetAttribute("EquipAnimation") == weapon then
                    character.Humanoid:EquipTool(tool)
                    return true
                end
            end
        end
        return false
    end
end

function MODULES:KillAllKnife()
    do
        if getgenv().config.lock.knife then return false end
        MODULES:EquipWeapon(knife)

        local me = game:GetService("Players").LocalPlayer
        local rs = game:GetService("ReplicatedStorage")
        local character = me.Character
        if not character then
            return
        end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return
        end

        for _, part in pairs(ENEMIES) do
            task.spawn(function()
                if part then
                    local origin = humanoidRootPart.Position
                    local direction = (part.Position - origin).Unit
                    rs.Remotes:WaitForChild("ThrowStart"):FireServer(origin, direction)
                    rs.Remotes:WaitForChild("ThrowHit"):FireServer(part, part.Position)
                end
            end)
        end
    end
end

function MODULES:KillAllGun()
    do
        if getgenv().config.lock.gun then return false end
        MODULES:EquipWeapon(gun)

        local me = game:GetService("Players").LocalPlayer
        local rs = game:GetService("ReplicatedStorage")
        local character = me.Character
        if not character then
            return
        end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        for _, part in pairs(ENEMIES) do
            task.spawn(function()
                if part then
                    rs.Remotes:WaitForChild("ShootGun"):FireServer(humanoidRootPart.Position, part.Position,
                        part,
                        part.Position)
                end
            end)
        end
    end
end
function MODULES:start()
while true do
    local players = game:GetService("Players")
    local ws = game:GetService("Workspace")

    task.wait(0.25)
    if not players.LocalPlayer.Character then return end

    for _, enemy in pairs(players:GetPlayers()) do
        task.spawn(function()
            if enemy and enemy ~= players.LocalPlayer and enemy.Team and enemy.Team ~= players.LocalPlayer.Team then
                if enemy.Character and enemy.Character.Parent == ws then
                    local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        ENEMIES[enemy] = hrp
                    end
                end
            end
        end)
    end
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    local me = game:GetService("Players").LocalPlayer
    local character = me.Character
    if not character then
        return
    end
    getgenv().config.lock.gun = true
    getgenv().config.lock.knife = true
    if getgenv().killing_loops.gun then
        MODULES:EquipWeapon(gun)
    elseif getgenv().killing_loops.knife then
        MODULES:EquipWeapon(knife)
    end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3)
    if not humanoidRootPart or not me:GetAttribute("Match") then
        return
    end
    local anchoredConnection
    anchoredConnection = humanoidRootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
        if not humanoidRootPart.Anchored then
            if getgenv().killing_loops.gun then
                getgenv().config.lock.gun = false
            elseif getgenv().killing_loops.knife then
                getgenv().config.lock.knife = false
            end
            if anchoredConnection then
                anchoredConnection:Disconnect()
            end
        end
    end)
end)
end
return MODULES

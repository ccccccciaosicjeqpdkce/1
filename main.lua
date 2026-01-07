local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local f = loadstring(game:HttpGet("https://raw.githubusercontent.com/ccccccciaosicjeqpdkce/1/refs/heads/main/mod.lua"))()

local Window = WindUI:CreateWindow({
    Title = "MVSD PREMIUM (FREE)",
    Icon = "file-code",
    Author = "by @cx85",
    Folder = "WindUI.MVSD",

    Size = UDim2.fromOffset(500, 300),
    MinSize = Vector2.new(400, 200),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Sky",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,

    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
            -- print("clicked")
        end,
    },
})

local MAIN = Window:Tab({
    Title = "Main",
    Icon = "house",
    Locked = false,
})

local gun = "Gun_Equip"
local knife = "Knife_Equip"

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    f:DeleteGunController() -- delete games controller
end)

local killingSection = MAIN:Section({
    Title = "Killing",
    Box = false,
    FontWeight = "SemiBold",
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17, -- Default Size
    Opened = false,
})

killingSection:Button({
    Title = "Kill All Once (Gun)",
    Desc = "",
    Locked = false,
    Callback = function()
        f:KillAllGun()
        WindUI:Notify({
            Title = "Kill All Once (Gun)",
            Content = "",
            Duration = 3,
            Icon = "star",
        })
    end
})
killingSection:Button({
    Title = "Kill All Once (Knife)",
    Desc = "",
    Locked = false,
    Callback = function()
        f:KillAllKnife()
        WindUI:Notify({
            Title = "Kill All Once (Knife)",
            Content = "",
            Duration = 3,
            Icon = "star",
        })
    end
})

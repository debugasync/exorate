loadstring(game:HttpGet("https://raw.githubusercontent.com/debugasync/fisch/refs/heads/main/ver.lua"))()
-- Configuration variables
local config = {
    fpsCap = 9999,
    disableChat = false,            -- Set to true to hide the chat
    enableBigButton = true,         -- Set to true to enlarge the button in the shake UI
    bigButtonScaleFactor = 2,       -- Scale factor for big button size
    shakeSpeed = 0.1,               -- Lower value means faster shake
    FreezeWhileFishing = true       -- Set to true to freeze your character while fishing
}

-- Set FPS cap
setfpscap(config.fpsCap)

-- Services
local players = game:GetService("Players")
local vim = game:GetService("VirtualInputManager")
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")
local localplayer = players.LocalPlayer
local playergui = localplayer.PlayerGui
local StarterGui = game:GetService("StarterGui")

-- Autofarm toggle variable
local isAutofarmEnabled = false

-- Function to toggle autofarm
function toggleAutofarm()
    isAutofarmEnabled = not isAutofarmEnabled
    if isAutofarmEnabled then
        print("Autofarm Enabled")
    else
        print("Autofarm Disabled")
        farm.freeze_character(false)  -- Ensure character is unfrozen when disabling autofarm
    end
end

-- Bind a key to toggle the autofarm
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        toggleAutofarm()
    end
end)

-- Disable chat if the option is enabled in config
if config.disableChat then
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end

-- Utility functions
local utility = {blacklisted_attachments = {"bob", "bodyweld"}}
function utility.simulate_click(x, y, mb)
    vim:SendMouseButtonEvent(x, y, (mb - 1), true, game, 1)
    vim:SendMouseButtonEvent(x, y, (mb - 1), false, game, 1)
end

function utility.move_fix(bobber)
    for _, value in pairs(bobber:GetDescendants()) do
        if value:IsA("Attachment") and table.find(utility.blacklisted_attachments, value.Name) then
            value:Destroy()
        end
    end
end

-- Farm functions
local farm = {}
function farm.find_rod()
    local character = localplayer.Character
    if not character then return nil end
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("rod") or tool.Name:find("Rod")) then
            return tool
        end
    end
    return nil
end

function farm.freeze_character(freeze)
    local character = localplayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = freeze and 0 or 16
            humanoid.JumpPower = freeze and 0 or 50
        end
    end
end

function farm.cast()
    local rod = farm.find_rod()
    if not rod then return end
    rod.events.cast:FireServer(100, 1)
end

function farm.shake()
    local shake_ui = playergui:FindFirstChild("shakeui")
    if shake_ui then
        local safezone = shake_ui:FindFirstChild("safezone")
        local button = safezone and safezone:FindFirstChild("button")

        if button then
            if config.enableBigButton then
                button.Size = UDim2.new(config.bigButtonScaleFactor, 0, config.bigButtonScaleFactor, 0)
            else
                button.Size = UDim2.new(1, 0, 1, 0) -- Reset to default size if disabled
            end

            if button.Visible then
                utility.simulate_click(
                    button.AbsolutePosition.X + button.AbsoluteSize.X / 2,
                    button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2,
                    1
                )
            end
        end
    end
end

function farm.reel()
    local reel_ui = playergui:FindFirstChild("reel")
    if not reel_ui then return end

    local reel_bar = reel_ui:FindFirstChild("bar")
    local reel_client = reel_bar and reel_bar:FindFirstChild("reel")
   
    if reel_client and reel_client.Disabled then
        reel_client.Disabled = false
    end

    local update_colors = getsenv(reel_client).UpdateColors
    if update_colors then
        setupvalue(update_colors, 1, 100)
        replicated_storage.events.reelfinished:FireServer(getupvalue(update_colors, 1), true)
    end
end

-- Main loop with rod check, configurable shake speed, and freeze feature
while task.wait(config.shakeSpeed) do
    if localplayer.Character and isAutofarmEnabled then  -- Ensure character exists before running autofarm
        local rod = farm.find_rod()
        if rod then
            if config.FreezeWhileFishing then
                farm.freeze_character(true)
            end
            farm.cast()
            farm.shake()
            farm.reel()
        else
            farm.freeze_character(false)
        end
    else
        farm.freeze_character(false)
    end
end

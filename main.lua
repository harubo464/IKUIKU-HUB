-- ============================================
-- Noob Hub + 僕ハンバーガー機能 統合版（無限連続動作版）
-- キック / 指名キック / バリア貫通 / スピンモード / 僕ハンバーガー
-- ============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- OrionLib
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

local Window = OrionLib:MakeWindow({
	Name = "Kick Hub + 僕ハンバーガー",
	HidePremium = false,
	SaveConfig = false,
	ConfigFolder = "KickHubBurger"
})

-- ========== 設定 ==========
local Settings = {
    NoclipEnabled = false,
    SpinEnabled = false,
    SpinSpeed = 30,
    KickAllEnabled = false,
    KickAllLoop = nil,
    AutoBurgerEatEnabled = false,
    AutoBurgerHoldEnabled = false
}

-- ========== 僕ハンバーガー用関数 ==========
local function getChar()
    return Workspace:FindFirstChild(LP.Name .. "_sub") or Workspace:FindFirstChild(LP.Name) or LP.Character
end

local function getAllItems()
    local items = {}
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("RemoteFunction") and obj.Name == "HoldItemRemoteFunction" then
                local holdPart = obj.Parent
                if holdPart and holdPart.Name == "HoldPart" then
                    local item = holdPart.Parent
                    if item then
                        table.insert(items, {
                            Name = item.Name,
                            Object = item,
                            Remote = obj,
                        })
                    end
                end
            end
        end
    end)
    return items
end

local UseRemote = nil
local function getUseRemote()
    if not UseRemote then
        UseRemote = ReplicatedStorage:FindFirstChild("HoldEvents") and ReplicatedStorage.HoldEvents:FindFirstChild("Use")
    end
    return UseRemote
end

local function useBurger(itemObj)
    local remote = getUseRemote()
    if remote then
        pcall(function()
            if itemObj then
                remote:FireServer(itemObj)
            else
                remote:FireServer(nil)
            end
        end)
    end
end

local function eatBurger(item)
    pcall(function()
        local char = getChar()
        if char and item and item.Remote and item.Object then
            item.Remote:InvokeServer(item.Object, char)
            useBurger(item.Object)
        end
    end)
end

local function holdBurger(item)
    pcall(function()
        local char = getChar()
        if char and item and item.Remote and item.Object then
            item.Remote:InvokeServer(item.Object, char)
        end
    end)
end

-- ========== 僕ハンバーガー（食べる）ループ ==========
local AutoBurgerEatLoop = nil

local function startAutoBurgerEat()
    if AutoBurgerEatLoop then return end
    
    AutoBurgerEatLoop = task.spawn(function()
        while Settings.AutoBurgerEatEnabled do
            local char = getChar()
            if char then
                local items = getAllItems()
                local hasBurger = false
                for _, item in pairs(items) do
                    local itemName = item.Name and item.Name:lower() or ""
                    if itemName:find("burger") or itemName:find("hamburger") then
                        hasBurger = true
                        eatBurger(item)
                    end
                end
                if not hasBurger then
                    useBurger(nil)
                end
            end
        end
        AutoBurgerEatLoop = nil
    end)
end

local function stopAutoBurgerEat()
    Settings.AutoBurgerEatEnabled = false
    if AutoBurgerEatLoop then
        task.cancel(AutoBurgerEatLoop)
        AutoBurgerEatLoop = nil
    end
end

-- ========== 僕ハンバーガー（持つ）ループ ==========
local AutoBurgerHoldLoop = nil

local function startAutoBurgerHold()
    if AutoBurgerHoldLoop then return end
    
    AutoBurgerHoldLoop = task.spawn(function()
        while Settings.AutoBurgerHoldEnabled do
            local char = getChar()
            if char then
                local items = getAllItems()
                for _, item in pairs(items) do
                    local itemName = item.Name and item.Name:lower() or ""
                    if itemName:find("burger") or itemName:find("hamburger") then
                        holdBurger(item)
                    end
                end
            end
        end
        AutoBurgerHoldLoop = nil
    end)
end

local function stopAutoBurgerHold()
    Settings.AutoBurgerHoldEnabled = false
    if AutoBurgerHoldLoop then
        task.cancel(AutoBurgerHoldLoop)
        AutoBurgerHoldLoop = nil
    end
end

-- ========== 僕ハンバーガー ==========
local function holdAllBurgers()
    local count = 0
    pcall(function()
        local char = getChar()
        if char then
            local items = getAllItems()
            for _, item in pairs(items) do
                local itemName = item.Name and item.Name:lower() or ""
                if itemName:find("burger") or itemName:find("hamburger") then
                    pcall(function()
                        item.Remote:InvokeServer(item.Object, char)
                        count = count + 1
                    end)
                end
            end
        end
    end)
    return count
end

-- ========== キック用 ==========
local function HRP(character)
    character = character or LP.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function SetNetworkOwner(part)
    if not part then return false end
    pcall(function()
        ReplicatedStorage.GrabEvents.SetNetworkOwner:FireServer(part, HRP().CFrame)
    end)
    return true
end

local function ungrab(part)
    if not part then return false end
    pcall(function()
        ReplicatedStorage.GrabEvents.DestroyGrabLine:FireServer(part)
    end)
    return true
end

-- ========== バリア貫通 ==========
local noclipConnection = nil
local noclipStepped = nil

local function enableNoclip()
    if noclipConnection then return end
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if not Settings.NoclipEnabled then return end
        local char = LP.Character
        if not char then return end
        
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    
    noclipStepped = RunService.Stepped:Connect(function()
        if not Settings.NoclipEnabled then return end
        local hrp = HRP()
        if not hrp then return end
        
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if noclipStepped then
        noclipStepped:Disconnect()
        noclipStepped = nil
    end
    
    local char = LP.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ========== スピンモード ==========
local spinConnection = nil

local function enableSpin()
    if spinConnection then return end
    
    spinConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not Settings.SpinEnabled then return end
        local hrp = HRP()
        if not hrp then return end
        
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed * deltaTime * 10), 0)
    end)
end

local function disableSpin()
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
end

-- ========== Blobman検索 ==========
local function findBlobman()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "CreatureBlobman" and v:FindFirstChild("VehicleSeat") then
            local seat = v.VehicleSeat
            local weld = seat and seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(LP.Character) then
                return v
            end
        end
    end
    return nil
end

-- ========== キック実行 ==========
local function executeKick(targetHRP, blobman)
    if not targetHRP or not blobman then return false end
    
    local success = false
    local myHRP = HRP()
    if not myHRP then return false end
    
    local leftDetector = blobman:FindFirstChild("LeftDetector")
    local leftWeld = leftDetector and leftDetector:FindFirstChild("LeftWeld")
    
    if leftDetector and leftWeld then
        pcall(function()
            blobman.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(leftDetector, myHRP, leftWeld)
            task.wait(0.05)
            SetNetworkOwner(targetHRP)
            task.wait(0.03)
            targetHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 20, 0)
            task.wait(0.05)
            ungrab(targetHRP)
            blobman.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(leftDetector, targetHRP, leftWeld)
        end)
        success = true
    else
        local rightDetector = blobman:FindFirstChild("RightDetector")
        local rightWeld = rightDetector and rightDetector:FindFirstChild("RightWeld")
        
        if rightDetector and rightWeld then
            pcall(function()
                blobman.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(rightDetector, myHRP, rightWeld)
                task.wait(0.05)
                SetNetworkOwner(targetHRP)
                task.wait(0.03)
                targetHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 20, 0)
                task.wait(0.05)
                ungrab(targetHRP)
                blobman.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(rightDetector, targetHRP, rightWeld)
            end)
            success = true
        end
    end
    
    return success
end

-- ========== テレポート ==========
local function teleportToTarget(targetHRP)
    local myHRP = HRP()
    if not myHRP or not targetHRP then return false end
    
    if Settings.NoclipEnabled then
        local direction = (targetHRP.Position - myHRP.Position).Unit
        myHRP.CFrame = CFrame.new(targetHRP.Position - direction * 1.5)
    else
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 2, -4)
    end
    return true
end

-- ========== 指名キック ==========
local function kickPlayer(targetPlayer)
    local blobman = findBlobman()
    if not blobman then
        OrionLib:MakeNotification({Name="エラー", Content="Blobmanが見つかりません", Time=1})
        return false
    end
    
    local targetHRP = HRP(targetPlayer.Character)
    if not targetHRP then
        OrionLib:MakeNotification({Name="エラー", Content="ターゲットが見つかりません", Time=1})
        return false
    end
    
    local myHRP = HRP()
    local originalPos = myHRP and myHRP.CFrame
    
    if myHRP then
        teleportToTarget(targetHRP)
        task.wait(0.05)
    end
    
    local success = executeKick(targetHRP, blobman)
    
    if myHRP and originalPos then
        pcall(function() myHRP.CFrame = originalPos end)
    end
    
    return success
end

-- ========== キック（1回） ==========
local function kickAllPlayersOnce()
    local blobman = findBlobman()
    if not blobman then
        OrionLib:MakeNotification({Name="エラー", Content="Blobmanが見つかりません", Time=1})
        return 0
    end
    
    local myHRP = HRP()
    local originalPos = myHRP and myHRP.CFrame
    local kickedCount = 0
    
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetHRP = HRP(player.Character)
            if targetHRP then
                table.insert(targets, targetHRP)
            end
        end
    end
    
    for _, targetHRP in ipairs(targets) do
        if myHRP then
            teleportToTarget(targetHRP)
            task.wait(0.05)
        end
        
        if executeKick(targetHRP, blobman) then
            kickedCount = kickedCount + 1
        end
        
        task.wait(0.15)
    end
    
    if myHRP and originalPos then
        pcall(function() myHRP.CFrame = originalPos end)
    end
    
    return kickedCount
end

-- ========== キックループ ==========
local function startKickAllLoop()
    if Settings.KickAllLoop then return end
    
    Settings.KickAllLoop = task.spawn(function()
        while Settings.KickAllEnabled do
            pcall(function()
                local blobman = findBlobman()
                if not blobman then
                    OrionLib:MakeNotification({Name="エラー", Content="Blobmanが見つかりません", Time=1})
                    return
                end
                
                local myHRP = HRP()
                local originalPos = myHRP and myHRP.CFrame
                
                local targets = {}
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LP and player.Character then
                        local targetHRP = HRP(player.Character)
                        if targetHRP then
                            table.insert(targets, targetHRP)
                        end
                    end
                end
                
                for _, targetHRP in ipairs(targets) do
                    if not Settings.KickAllEnabled then break end
                    
                    if myHRP then
                        teleportToTarget(targetHRP)
                        task.wait(0.05)
                    end
                    
                    executeKick(targetHRP, blobman)
                    task.wait(0.15)
                end
                
                if myHRP and originalPos then
                    pcall(function() myHRP.CFrame = originalPos end)
                end
            end)
            
            if Settings.KickAllEnabled then
                task.wait(0.5)
            end
        end
        
        Settings.KickAllLoop = nil
    end)
end

local function stopKickAllLoop()
    Settings.KickAllEnabled = false
    if Settings.KickAllLoop then
        task.cancel(Settings.KickAllLoop)
        Settings.KickAllLoop = nil
    end
end

-- ========== プレイヤーリスト ==========
local function getPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(list, player.DisplayName .. " (" .. player.Name .. ")")
        end
    end
    return list
end

local function getPlayerByDisplayName(displayString)
    for _, player in ipairs(Players:GetPlayers()) do
        local label = player.DisplayName .. " (" .. player.Name .. ")"
        if label == displayString then
            return player
        end
    end
    return nil
end

local selectedPlayerName = nil

-- ========== UI作成 ==========

local MainTab = Window:MakeTab({
    Name = "Kick & 僕ハンバーガー",
    Icon = "rbxassetid://7733916988",
    PremiumOnly = false
})

-- ========== キックセクション ==========
MainTab:AddSection({ Name = "🥾 キック機能" })

MainTab:AddToggle({
    Name = "🧱 バリア貫通 (壁抜け)",
    Default = false,
    Color = Color3.fromRGB(255, 255, 0),
    Callback = function(state)
        Settings.NoclipEnabled = state
        if state then
            enableNoclip()
            OrionLib:MakeNotification({Name="バリア貫通", Content="🟢 有効", Time=1})
        else
            disableNoclip()
            OrionLib:MakeNotification({Name="バリア貫通", Content="🔴 無効", Time=1})
        end
    end
})

MainTab:AddToggle({
    Name = "🌀 スピンモード",
    Default = false,
    Color = Color3.fromRGB(0, 255, 255),
    Callback = function(state)
        Settings.SpinEnabled = state
        if state then
            enableSpin()
            OrionLib:MakeNotification({Name="スピンモード", Content="🟢 有効", Time=1})
        else
            disableSpin()
            OrionLib:MakeNotification({Name="スピンモード", Content="🔴 無効", Time=1})
        end
    end
})

MainTab:AddSlider({
    Name = "🌀 スピン速度",
    Min = 1,
    Max = 100,
    Default = 30,
    Color = Color3.fromRGB(0, 255, 255),
    Increment = 1,
    ValueName = "speed",
    Callback = function(value)
        Settings.SpinSpeed = value
    end
})

local playerDropdown = MainTab:AddDropdown({
    Name = "プレイヤー選択",
    Options = getPlayerList(),
    Callback = function(value)
        selectedPlayerName = value
    end
})

MainTab:AddButton({
    Name = "🔄 プレイヤーリスト更新",
    Callback = function()
        playerDropdown:Refresh(getPlayerList(), true)
    end
})

MainTab:AddButton({
    Name = "🦵 指名キック",
    Callback = function()
        if not selectedPlayerName then
            OrionLib:MakeNotification({Name="エラー", Content="プレイヤーを選択してください", Time=1})
            return
        end
        
        local target = getPlayerByDisplayName(selectedPlayerName)
        if target then
            if kickPlayer(target) then
                OrionLib:MakeNotification({Name="キック成功", Content=target.DisplayName, Time=1})
            else
                OrionLib:MakeNotification({Name="キック失敗", Content="もう一度お試しください", Time=1})
            end
        end
    end
})

MainTab:AddButton({
    Name = "🚀 テレポート",
    Callback = function()
        if not selectedPlayerName then
            OrionLib:MakeNotification({Name="エラー", Content="プレイヤーを選択してください", Time=1})
            return
        end
        
        local target = getPlayerByDisplayName(selectedPlayerName)
        if target then
            local targetHRP = HRP(target.Character)
            if targetHRP then
                teleportToTarget(targetHRP)
                OrionLib:MakeNotification({Name="テレポート", Content=target.DisplayName, Time=1})
            end
        end
    end
})

MainTab:AddToggle({
    Name = "🔄 キック自動ループ",
    Default = false,
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(state)
        Settings.KickAllEnabled = state
        if state then
            startKickAllLoop()
            OrionLib:MakeNotification({Name="キック自動", Content="🟢 ON - キックし続けます", Time=2})
        else
            stopKickAllLoop()
            OrionLib:MakeNotification({Name="キック自動", Content="🔴 OFF - 停止しました", Time=2})
        end
    end
})

MainTab:AddButton({
    Name = "💥 キック (1回のみ)",
    Callback = function()
        local count = kickAllPlayersOnce()
        OrionLib:MakeNotification({
            Name = "キック",
            Content = count .. " 人のプレイヤーをキックしました",
            Time = 2
        })
    end
})

-- ========== 僕ハンバーガーセクション ==========
MainTab:AddSection({ Name = "🍔 僕ハンバーガー" })

MainTab:AddToggle({
    Name = "🍔 僕ハンバーガー",
    Default = false,
    Color = Color3.fromRGB(255, 150, 50),
    Callback = function(state)
        if state and Settings.AutoBurgerHoldEnabled then
            Settings.AutoBurgerHoldEnabled = false
            stopAutoBurgerHold()
        end
        Settings.AutoBurgerEatEnabled = state
        if state then
            startAutoBurgerEat()
            OrionLib:MakeNotification({Name="僕ハンバーガー", Content="🟢 ON", Time=1})
        else
            stopAutoBurgerEat()
            OrionLib:MakeNotification({Name="僕ハンバーガー", Content="🔴 OFF", Time=1})
        end
    end
})

MainTab:AddToggle({
    Name = "🍔 僕ハンバーガー",
    Default = false,
    Color = Color3.fromRGB(255, 200, 100),
    Callback = function(state)
        if state and Settings.AutoBurgerEatEnabled then
            Settings.AutoBurgerEatEnabled = false
            stopAutoBurgerEat()
        end
        Settings.AutoBurgerHoldEnabled = state
        if state then
            startAutoBurgerHold()
            OrionLib:MakeNotification({Name="僕ハンバーガー", Content="🟢 ON", Time=1})
        else
            stopAutoBurgerHold()
            OrionLib:MakeNotification({Name="僕ハンバーガー", Content="🔴 OFF", Time=1})
        end
    end
})

MainTab:AddButton({
    Name = "🍔 僕ハンバーガー",
    Callback = function()
        local count = holdAllBurgers()
        OrionLib:MakeNotification({Name="僕ハンバーガー", Content=count .. "個 僕ハンバーガー", Time=1})
    end
})

MainTab:AddLabel("※ 僕ハンバーガー")
MainTab:AddLabel("※ 僕ハンバーガー")
MainTab:AddLabel("※ Blobmanに乗っているとキック機能が使えます")

-- ========== プレイヤー追加/削除でリスト更新 ==========
Players.PlayerAdded:Connect(function()
    playerDropdown:Refresh(getPlayerList(), true)
end)

Players.PlayerRemoving:Connect(function()
    playerDropdown:Refresh(getPlayerList(), true)
end)

-- ========== 初期化 ==========
OrionLib:Init()

OrionLib:MakeNotification({
    Name = "Kick Hub + 僕ハンバーガー",
    Content = "✅ キック機能\n✅ 僕ハンバーガー\n✅ 僕ハンバーガー\n✅ 僕ハンバーガー",
    Image = "rbxassetid://7733916988",
    Time = 4
})

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "CFrame Cloner",
   LoadingTitle = "Menyiapkan UI...",
   LoadingSubtitle = "by makeitraw",
   ConfigurationSaving = {
      Enabled = false
   }
})

local MainTab = Window:CreateTab("Main", 4483362458) 

MainTab:CreateButton({
   Name = "Copy CFrame to Clipboard",
   Callback = function()
       local player = game.Players.LocalPlayers
       if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
           local cf = player.Character.HumanoidRootPart.CFrame
           
           local cfString = "CFrame.new(" .. tostring(cf) .. ")"
           
           if setclipboard then
               setclipboard(cfString)
               Rayfield:Notify({
                  Title = "Berhasil!",
                  Content = "CFrame berhasil disalin ke clipboard.",
                  Duration = 3,
                  Image = 4483362458,
               })
           else
               warn("Executor Anda tidak mendukung fungsi setclipboard.")
           end
       end
   end,
})

MainTab:CreateButton({
   Name = "Copy Position Only",
   Callback = function()
       local player = game.Players.LocalPlayer
       if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
           local pos = player.Character.HumanoidRootPart.Position
           local posString = "Vector3.new(" .. tostring(pos) .. ")"
           
           if setclipboard then
               setclipboard(posString)
               Rayfield:Notify({
                  Title = "Berhasil!",
                  Content = "Posisi berhasil disalin!",
                  Duration = 3,
                  Image = 4483362458,
               })
           end
       end
   end,
})
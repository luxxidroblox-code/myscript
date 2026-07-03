-- [[ DEBUG VERSION: AUTO DRAG BRIDGE ]] --

local function runDragBridgePassDebug()
    if dragBridgePassActive then return end 
    
    local seat = currentVehicle and (currentVehicle:IsA("VehicleSeat") and currentVehicle or currentVehicle:FindFirstChildWhichIsA("VehicleSeat", true))
    if not seat then 
        warn("[DEBUG-DRAG] Gagal memulai race: Kursi tidak ditemukan!") 
        return 
    end
    
    local dragRace = findDragRace()
    if not dragRace then 
        warn("[DEBUG-DRAG] Folder/Model DragRace tidak ditemukan di Workspace!") 
        return 
    end
    
    local startDet, c1, c2, c3, finishDet = findDragDetectors(dragRace) 
    if not startDet or not finishDet then
        warn("[DEBUG-DRAG] Part Detektor (Start/Finish) hilang atau berganti nama!") 
        return
    end 
    
    dragBridgePassActive = true
    dragBridgeRunning = true 
    
    print("[DEBUG-DRAG] Memulai eksploitasi balapan... Menghentikan mobil sementara.")
    holdVehicleStill(0.5) 
    
    -- Picu Garis Start
    print("[DEBUG-DRAG] Memicu: START DETECTOR")
    touchDragDetector(startDet, seat.CFrame)
    
    print("[DEBUG-DRAG] Menunggu jeda lampu hijau (" .. tostring(DRAG_BRIDGE_START_HOLD) .. " detik)...")
    holdVehicleStill(DRAG_BRIDGE_START_HOLD)
    dragBridgeRunning = false 
    
    -- Picu Checkpoint secara berurutan
    local checkpoints = {c1, c2, c3}
    for index, checkpoint in ipairs(checkpoints) do
        if checkpoint and farmingActive then 
            print("[DEBUG-DRAG] Memicu: CHECKPOINT " .. index)
            touchDragDetector(checkpoint, seat.CFrame)
            task.wait(DRAG_BRIDGE_CHECKPOINT_DELAY) 
        else
            print("[DEBUG-DRAG] Checkpoint " .. index .. " dilewati (tidak ada part atau farm mati).")
        end
    end 
    
    -- Picu Garis Finish
    if farmingActive then
        print("[DEBUG-DRAG] Memicu: FINISH DETECTOR! Balapan Selesai.")
        touchDragDetector(finishDet, seat.CFrame) 
        dragBridgeRaceCount = dragBridgeRaceCount + 1
        print("[DEBUG-DRAG] Total Balapan Berhasil Terlewati: " .. dragBridgeRaceCount)
        
        if dragBridgeRaceCount >= DRAG_BRIDGE_LIMIT then 
            warn("[DEBUG-DRAG] Batas limit tercapai (" .. DRAG_BRIDGE_LIMIT .. "). Memicu Server Rejoin untuk keamanan!")
            -- Logika teleport / server hop dijalankan di sini
        end 
    end
    
    dragBridgeRunning = false
    dragBridgePassActive = false 
end

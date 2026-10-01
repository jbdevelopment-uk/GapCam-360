local MODEL = `gapcam`

local cam, prop, vehicle = nil, nil, nil
local viewing = false
local recording = false

local function notify(desc, kind)
    lib.notify({ title = 'Gap Cam', description = desc, type = kind or 'inform' })
end

local function loadModel()
    if not IsModelInCdimage(MODEL) then return false end
    RequestModel(MODEL)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(MODEL) do
        if GetGameTimer() > timeout then return false end
        Wait(0)
    end
    return true
end

local function getTargetVehicle()
    local veh = GetVehiclePedIsIn(cache.ped, false)
    if veh ~= 0 then return veh end
    return lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.placeDistance, true) or 0
end

local function attachToVehicle(obj, veh)
    local pos = GetOffsetFromEntityGivenWorldCoords(veh, GetEntityCoords(obj))
    local rot = GetEntityRotation(obj, 2) - GetEntityRotation(veh, 2)
    AttachEntityToEntity(obj, veh, -1, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, false, false, false, false, 2, true)
end

local function keyboardPlace(obj, veh)
    lib.showTextUI('Arrows: move | PgUp/PgDn: height | Q/E: rotate | Shift: fine | Enter: confirm | Backspace: cancel')
    local off = GetOffsetFromEntityGivenWorldCoords(veh, GetEntityCoords(obj))
    local heading = 0.0
    local ok = false
    while true do
        Wait(0)
        DisableControlAction(0, 200, true)
        local s = IsControlPressed(0, 21) and 0.002 or 0.01
        if IsControlPressed(0, 172) then off += vec3(0, s, 0) end
        if IsControlPressed(0, 173) then off -= vec3(0, s, 0) end
        if IsControlPressed(0, 175) then off += vec3(s, 0, 0) end
        if IsControlPressed(0, 174) then off -= vec3(s, 0, 0) end
        if IsControlPressed(0, 10) then off += vec3(0, 0, s) end
        if IsControlPressed(0, 11) then off -= vec3(0, 0, s) end
        if IsControlPressed(0, 44) then heading += s * 100 end
        if IsControlPressed(0, 38) then heading -= s * 100 end
        AttachEntityToEntity(obj, veh, -1, off.x, off.y, off.z, 0.0, 0.0, heading, false, false, false, false, 2, true)
        if IsControlJustPressed(0, 191) then ok = true break end
        if IsControlJustPressed(0, 177) then break end
    end
    lib.hideTextUI()
    return ok
end

local function gizmoPlace(obj)
    local data = exports.object_gizmo:useGizmo(obj)
    if not data then return false end
    SetEntityCoords(obj, data.position.x, data.position.y, data.position.z, false, false, false, false)
    SetEntityRotation(obj, data.rotation.x, data.rotation.y, data.rotation.z, 2, false)
    return true
end

local function useGizmo()
    return GetResourceState('object_gizmo') == 'started'
end

local function place()
    if prop and DoesEntityExist(prop) then return notify('You already have a gap cam mounted. Remove it first.', 'error') end
    prop, vehicle = nil, nil
    if not lib.callback.await('gapcam:canPlace', false) then return notify('You need a Gap Cam.', 'error') end
    local veh = getTargetVehicle()
    if veh == 0 then return notify('Get in or stand next to a vehicle.', 'error') end
    if not loadModel() then return notify('gapcam model failed to load (is the resource started?).', 'error') end

    local start = GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, 1.5)
    local obj = CreateObject(MODEL, start.x, start.y, start.z, true, true, false)
    SetModelAsNoLongerNeeded(MODEL)
    SetEntityCollision(obj, false, false)
    SetEntityRotation(obj, GetEntityRotation(veh, 2), 2, false)

    FreezeEntityPosition(veh, true)

    local confirmed
    if useGizmo() then
        confirmed = gizmoPlace(obj)
        if confirmed then attachToVehicle(obj, veh) end
    else
        confirmed = keyboardPlace(obj, veh)
    end

    FreezeEntityPosition(veh, false)

    if not confirmed then
        DeleteEntity(obj)
        return notify('Placement cancelled.')
    end

    if not lib.callback.await('gapcam:consume', false) then
        DeleteEntity(obj)
        return notify('You need a Gap Cam item.', 'error')
    end

    prop, vehicle = obj, veh
    notify('Gap cam mounted. Use /gapcamview or the target menu to look through it.', 'success')
end

local function reposition()
    if not prop or not DoesEntityExist(prop) then return notify('No gap cam placed.', 'error') end
    DetachEntity(prop, true, true)
    FreezeEntityPosition(vehicle, true)
    if useGizmo() then
        gizmoPlace(prop)
        attachToVehicle(prop, vehicle)
    else
        keyboardPlace(prop, vehicle)
    end
    FreezeEntityPosition(vehicle, false)
end

local function remove()
    if viewing then
        viewing = false
        Wait(500)
    end
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
        TriggerServerEvent('gapcam:returnItem')
    end
    prop, vehicle = nil, nil
end

local function drawHud(fov)
    SetTextFont(4)
    SetTextScale(0.0, 0.35)
    SetTextColour(255, 255, 255, 220)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(('GAP CAM  |  FOV %d  |  Mouse: look  Scroll: zoom  R: reset  Enter: %s  Backspace: exit'):format(math.floor(fov), recording and 'stop rec' or 'record'))
    EndTextCommandDisplayText(0.25, 0.95)

    if recording then
        SetTextFont(4)
        SetTextScale(0.0, 0.45)
        SetTextColour(255, 40, 40, 255)
        SetTextOutline()
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName('● REC')
        EndTextCommandDisplayText(0.93, 0.04)
    end
end

local function view()
    if viewing then return end
    if not prop or not DoesEntityExist(prop) then return notify('No gap cam placed.', 'error') end
    viewing = true

    local fov = Config.fov.default
    local yaw, pitch = 0.0, 0.0

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, fov)
    SetCamNearClip(cam, 0.05)
    RenderScriptCams(true, true, 400, true, false)

    while viewing and DoesEntityExist(prop) do
        Wait(0)

        local lens = GetOffsetFromEntityInWorldCoords(prop, Config.lensOffset.x, Config.lensOffset.y, Config.lensOffset.z)
        if #(GetEntityCoords(cache.ped) - lens) > Config.maxDistance then
            notify('Out of range of the gap cam.', 'error')
            break
        end

        DisableAllControlActions(0)
        EnableControlAction(0, 249, true)

        local sens = Config.lookSpeed * (fov / Config.fov.default)
        yaw = (yaw - GetDisabledControlNormal(0, 1) * sens) % 360.0
        pitch = math.max(-89.0, math.min(89.0, pitch - GetDisabledControlNormal(0, 2) * sens))

        if IsDisabledControlJustPressed(0, 241) then fov = math.max(Config.fov.min, fov - Config.fov.step) end
        if IsDisabledControlJustPressed(0, 242) then fov = math.min(Config.fov.max, fov + Config.fov.step) end
        if IsDisabledControlJustPressed(0, 45) then yaw, pitch, fov = 0.0, 0.0, Config.fov.default end
        SetCamFov(cam, fov)

        SetCamCoord(cam, lens.x, lens.y, lens.z)
        SetCamRot(cam, pitch, 0.0, GetEntityHeading(prop) + yaw, 2)
        SetFocusPosAndVel(lens.x, lens.y, lens.z, 0.0, 0.0, 0.0)

        drawHud(fov)

        if IsDisabledControlJustPressed(0, 191) then
            if recording then
                StopRecordingAndSaveClip()
                recording = false
                notify('Clip saved. Open it in the Rockstar Editor.', 'success')
            else
                StartRecording(1)
                recording = true
                notify('Recording started.')
            end
        end

        if IsDisabledControlJustPressed(0, Config.exitKey) then break end
    end

    if recording then
        StopRecordingAndSaveClip()
        recording = false
        notify('Clip saved. Open it in the Rockstar Editor.', 'success')
    end

    viewing = false
    ClearFocus()
    RenderScriptCams(false, true, 400, true, false)
    Wait(400)
    DestroyCam(cam, false)
    cam = nil
end

RegisterNetEvent('gapcam:use', place)
RegisterCommand(Config.Commands.place, place, false)
RegisterCommand(Config.Commands.view, view, false)
RegisterCommand(Config.Commands.edit, reposition, false)
RegisterCommand(Config.Commands.remove, remove, false)


AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    ClearFocus()
    if recording then StopRecordingAndSaveClip() end
    RenderScriptCams(false, false, 0, true, false)
    if cam then DestroyCam(cam, false) end
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
end)

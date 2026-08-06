-- The Freehold of Una Court - gameplay loader
print("UnaCourtLoader.lua loaded")

-- GameEvents.GameSave fires inside the Community Patch DLL immediately before
-- native serialization. Anything queued here therefore runs on a later UI
-- frame, after the synchronous save has finished. The same queue also gives
-- load restoration one quiet frame after all gameplay scripts initialize.
local deferredTasks = {}
local deferredFrames = 0
local updateCallbacks = {}

function UnaCourt_RegisterUpdate(callback)
    if type(callback) ~= "function" then return false end
    updateCallbacks[#updateCallbacks + 1] = callback
    return true
end

function UnaCourt_QueueDeferredRestore(callback)
    if type(callback) ~= "function" then return false end
    deferredTasks[#deferredTasks + 1] = callback
    deferredFrames = math.max(deferredFrames, 1)
    return true
end

if ContextPtr ~= nil and ContextPtr.SetUpdate ~= nil then
    UnaCourt_RegisterUpdate(function()
        if #deferredTasks == 0 then return end
        if deferredFrames > 0 then
            deferredFrames = deferredFrames - 1
            return
        end

        local tasks = deferredTasks
        deferredTasks = {}
        for _, callback in ipairs(tasks) do
            local ok, err = pcall(callback)
            if not ok then print("Una Court deferred restore failed: " .. tostring(err)) end
        end
    end)
    ContextPtr:SetUpdate(function(deltaTime)
        for _, callback in ipairs(updateCallbacks) do
            local ok, err = pcall(callback, deltaTime)
            if not ok then print("Una Court gameplay update failed: " .. tostring(err)) end
        end
    end)
else
    print("Una Court warning: deferred restore queue is unavailable")
end

local function UnaInclude(fileName)
    local ok, err = pcall(function() include(fileName) end)
    if ok then
        print("Una Court included " .. fileName)
    else
        print("Una Court failed to include " .. fileName .. ": " .. tostring(err))
    end
end

UnaInclude("UnaCourtCore.lua")
UnaInclude("UnaCourtPossession.lua")
UnaInclude("DominionCore.lua")
UnaInclude("DominionBodySwap.lua")

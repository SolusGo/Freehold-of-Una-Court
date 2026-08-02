-- The Freehold of Una Court - gameplay loader
print("UnaCourtLoader.lua loaded")

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

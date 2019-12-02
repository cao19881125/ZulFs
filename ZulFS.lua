local ZFrm = CreateFrame("Frame", "ZulFrame", UIParent)
local disabled = true
ZFrm:Hide()

local WIDTH = 370
local HEIGHT = 370

local handlers = {}

local function Call(func)
    xpcall(func, function (err)
        print( "ERROR:", err )
    end)
end

local function RegisterEvent(event, handler)
    ZFrm:RegisterEvent(event)
    if (type(handler) == "function") then
        handlers[event] = handler
    end
end

local function InitFrame()
    ZFrm:SetWidth(WIDTH)
    ZFrm:SetHeight(HEIGHT)
    ZFrm:SetPoint("CENTER", UIParent, "CENTER")

    ZFrm:SetScript("OnEvent", function (self, event, ...)
        local args={...}
        -- print("ZulFS-E: " .. event .. " | " .. table.concat( args, ", "))
        local handler = handlers[event]
        if (handler) then
            handler(event, args)
        end
    end)
end

local function CreateMark()
    ZFrm.portrait = ZFrm:CreateTexture("ZulFrame_Portrait", "BACKGROUND")
    --ZFrm.portrait:SetRotation(0)
    ZFrm.portrait:SetAllPoints()
    -- ZFrm.portrait:SetTexture(1.0, 0.0, 0.0)
    ZFrm.portrait:SetTexture("Interface\\AddOns\\ZulFS\\range")
    ZFrm.portrait:SetBlendMode("ADD")

end
local CurrentZoom = 30
local function ResizeMark()
    local zoom = GetCameraZoom()
    if (zoom ~= CurrentZoom) then
        CurrentZoom = zoom
        local scale = UIParent:GetScale()
        local zoomFactorScale = GetCVar("cameraDistanceMaxZoomFactor")
        local base = 50 / zoom / scale * (zoomFactorScale / 4)
        local height = HEIGHT * base
        local width = WIDTH * base
        --print(
            --"zulfs：缩放变化调整距离指示器大小",
            --"\n当前镜头距离 " .. zoom,
            --"\n当前 UI 缩放 " .. scale,
            --"\n当前最大距离 " .. zoomFactorScale,
            --"\n设定大小" .. height .. ' X ' .. width
        --)
        ZFrm:SetHeight(height)
        ZFrm:SetWidth(width)
    end
end

-- TODO 调整人物朝向后冰箱
-- TODO 在冰箱后检测大批量免疫间隔，提醒出冰箱冰环
local ZFInfo =  ZFrm:CreateFontString("ZulInfo", "OVERLAY", "NumberFont_Outline_Huge")
ZFInfo:SetPoint("CENTER", UIParent, 0, 100)
ZFInfo:SetTextHeight(50)
ZFInfo:SetAlpha(0.5)
local ZFInfoState = 0
local function StartCombat()
    -- RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', function () -- body end)
    --检测吹风冷却时间，在结束前提醒释放
    ZFrm:SetScript('OnUpdate', function ()
        ResizeMark()
        start, duration, enable = GetSpellCooldown(10159)
        changePosTimeLimit = 3
        castTimeLimit = 0.5
        if (start > 0 and enable > 0 and duration ~= 1.5) then
            local remain = duration - (GetTime() - start)
            if (remain > castTimeLimit and remain <= changePosTimeLimit and ZFInfoState == 0) then
            -- 结束前提醒调整位置
                ZFInfoState = 1
                ZFInfo:SetText("快调整")
                ZFInfo:Show()
            elseif (remain <= castTimeLimit and remain > 0 and ZFInfoState == 1) then
                ZFInfoState = 2
                ZFInfo:SetText("快吹风")
                ZFInfo:Show()
            end
        elseif (ZFInfoState > 0) then
            ZFInfoState = 0
            ZFInfo:SetText("")
            ZFInfo:Hide()
        end
    end)
end

local function StopCombat()
    ZFrm:SetScript('OnUpdate', ResizeMark)
    ZFInfoState = 0
    ZFInfo:SetText("")
    ZFInfo:Hide()
end

local function EnableZulFS()
    ZFrm:Show()
    MoveViewUpStart()
    ConsoleExec("cameraDistanceMaxZoomFactor 4")
    disabled = false
    RegisterEvent('PLAYER_REGEN_DISABLED', StartCombat)
    RegisterEvent('PLAYER_REGEN_ENABLED', StopCombat)

    local in_combat = InCombatLockdown()

    if(in_combat)then
        StartCombat()
    else
        ZFrm:SetScript('OnUpdate', ResizeMark)
    end

end

local function DisableZulFS()
    ZFrm:Hide()
    MoveViewUpStop()
    disabled = true
    ZFrm:UnregisterEvent('PLAYER_REGEN_DISABLED')
    ZFrm:UnregisterEvent('PLAYER_REGEN_ENABLED')
    ZFrm:SetScript('OnUpdate', nil)
end

SLASH_ZULFS1 = "/zulfs"
SlashCmdList["ZULFS"] = function(msg)
    if (disabled) then
        EnableZulFS()
    else
        DisableZulFS()
    end
end

Call(InitFrame)
Call(CreateMark)
-- Disable animations
hs.window.animationDuration = 0

-- Window hints
hs.hints.fontSize = 30
hs.hints.iconAlpha = 1.0
hs.hints.showTitleThresh = 0
hs.hints.hintChars = {'Q', 'W', 'E', 'A', 'S', 'D', 'Z', 'X', 'C', 'U', 'I', 'O', 'J', 'K', 'L', 'M', 'R', 'T', 'Y', 'F', 'G', 'H', 'V', 'B', 'N'}
hs.hotkey.bind({"cmd"}, "escape", function()
    hs.hints.windowHints()
end)

-- Window manipulation with WinWin
hs.loadSpoon('WinWin')
-- hints
hs.hotkey.bind({"cmd"}, "escape", function()
    hs.hints.windowHints()
end)
-- undo
-- not working... seems to undo all previous moves?
-- hs.hotkey.bind({"ctrl", "shift", "cmd"}, "z", function()
--     spoon.WinWin.undo()
-- end)
-- full
hs.hotkey.bind({"ctrl", "cmd"}, "o", function()
    spoon.WinWin:moveAndResize('maximize')
end)
-- halves
hs.hotkey.bind({"ctrl", "cmd"}, "k", function()
    spoon.WinWin:moveAndResize('halfleft')
end)
hs.hotkey.bind({"ctrl", "cmd"}, ";", function()
    spoon.WinWin:moveAndResize('halfright')
end)
hs.hotkey.bind({"ctrl", "cmd", "shift"}, "o", function()
    spoon.WinWin:moveAndResize('halfup')
end)
hs.hotkey.bind({"ctrl", "cmd"}, "l", function()
    spoon.WinWin:moveAndResize('halfdown')
end)
-- corners
hs.hotkey.bind({"ctrl", "cmd", "alt"}, "k", function()
    spoon.WinWin:moveAndResize('cornerSW')
end)
hs.hotkey.bind({"ctrl", "cmd", "alt"}, ";", function()
    spoon.WinWin:moveAndResize('cornerSE')
end)
hs.hotkey.bind({"shift", "cmd", "alt"}, "k", function()
    spoon.WinWin:moveAndResize('cornerNW')
end)
hs.hotkey.bind({"shift", "cmd", "alt"}, ";", function()
    spoon.WinWin:moveAndResize('cornerNE')
end)
-- next screen
hs.hotkey.bind({"cmd", "alt"}, "o", function()
    spoon.WinWin:moveToScreen('next')
    spoon.WinWin:moveAndResize('maximize')
end)
hs.hotkey.bind({"cmd", "alt"}, ";", function()
    spoon.WinWin:moveToScreen('next')
    spoon.WinWin:moveAndResize('halfright')
end)
hs.hotkey.bind({"cmd", "alt"}, "k", function()
    spoon.WinWin:moveToScreen('next')
    spoon.WinWin:moveAndResize('halfleft')
end)
hs.hotkey.bind({"cmd", "alt", "shift"}, "o", function()
    spoon.WinWin:moveToScreen('next')
    spoon.WinWin:moveAndResize('halfup')
end)
hs.hotkey.bind({"cmd", "alt"}, "l", function()
    spoon.WinWin:moveToScreen('next')
    spoon.WinWin:moveAndResize('halfdown')
end)
-- focus underneath
hs.hotkey.bind({"ctrl", "cmd"}, "'", function()
    local fw=hs.window.focusedWindow()
    local id,frame=fw:id(),fw:frame()
    local wins=hs.window.orderedWindows()
    -- get windows on this monitor
    for z=#wins,1,-1 do
        local w=wins[z]
        if id==w:id() then
            table.remove(wins,z)
        end
    end
    -- find overlapping windows
    local toRaise,topz,didwork={}
    repeat
        for z=#wins,1,-1 do
            didwork=nil
            local wf=wins[z]:frame()
            if frame:intersect(wf).area>0 then
                topz=z
                if not toRaise[z] then
                    didwork=true
                    toRaise[z]=true
                    frame=frame:union(wf)
                    break
                end
            end
        end
    until not didwork
    -- focus first underlying window
    if topz then
        wins[topz]:focus()
    end
end)

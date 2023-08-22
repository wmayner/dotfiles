hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.ShiftIt = {
    url = "https://github.com/peterklijn/hammerspoon-shiftit",
    desc = "ShiftIt spoon repository",
    branch = "master",
 }

spoon.SpoonInstall:andUse("ShiftIt", { repo = "ShiftIt" })
-- Use Vim arrow keys
spoon.ShiftIt:bindHotkeys({
    maximum = { { 'cmd', 'ctrl' }, 'o' },
    left = { { 'cmd', 'ctrl' }, 'k' },
    right = { { 'cmd', 'ctrl' }, ';' },
    down = { { 'cmd', 'ctrl' }, 'l' },
    up = { { 'cmd', 'alt', 'shift' }, 'o' },
    upleft = { { 'cmd', 'alt', 'shift' }, 'k' },
    upright = { { 'cmd', 'alt', 'shift' }, ';' },
    botleft = { { 'cmd', 'alt', 'ctrl' }, 'k' },
    botright = { { 'cmd', 'alt', 'ctrl' }, ';' },
    center = { { 'cmd', 'alt', 'ctrl' }, 'c' },
    nextScreen = { { 'cmd', 'alt' }, 'o' },
    previousScreen = { { 'cmd', 'alt' }, 'l' },
    toggleFullScreen = { { 'cmd', 'alt', 'ctrl' }, 'f' },
    toggleZoom = { { 'cmd', 'alt', 'ctrl' }, 'z' },
    resizeOut = { { 'cmd', 'alt', 'ctrl' }, '=' },
    resizeIn = { { 'cmd', 'alt', 'ctrl' }, '-' }
  })

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

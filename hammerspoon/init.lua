-- Start the ipc server so the `hs` CLI works
require('hs.ipc')

hs.window.animationDuration = 0

----------------------------------------------------------------------
-- Resize windows
----------------------------------------------------------------------

local function rectEq(a,b,eps)
  eps=eps or 1
  return math.abs(a.x-b.x)<eps and math.abs(a.y-b.y)<eps and math.abs(a.w-b.w)<eps and math.abs(a.h-b.h)<eps
end
local function axWin(w)
  local ok, ax = pcall(hs.axuielement.windowElement, w)
  return ok and ax or nil
end

-- Low-level setters that try AX first (stronger), then window API
local function setAXSizePos(w, size, pos)
  local ax = axWin(w)
  if ax then
    if size then pcall(function() ax.AXSize = size end) end
    if pos  then pcall(function() ax.AXPosition = pos end) end
  else
    if size then w:setSize(size.w, size.h) end
    if pos  then w:setTopLeft(pos) end
  end
end

-- Brute clamp: shrink hard, recentre, then fit to target frame
function FitToScreen(pad)
  local w = hs.window.frontmostWindow(); if not w then return end
  if w:isFullScreen() then w:setFullScreen(false); hs.timer.usleep(150000) end

  local s = w:screen():frame()        -- visible frame (no menu bar/Dock)
  pad = pad or 0
  local t = { x = s.x+pad, y = s.y+pad, w = s.w-2*pad, h = s.h-2*pad }

  -- 1) Quick try
  w:setFrame(t, 0)
  if rectEq(w:frame(), t) then return end

  -- 2) Brute approach: shrink to tiny, center, then expand to target
  local shrinkW, shrinkH = 200, 160
  local center = { x = s.x + (s.w - shrinkW)/2, y = s.y + (s.h - shrinkH)/2 }
  setAXSizePos(w, {w = shrinkW, h = shrinkH}, center)

  -- give AX a beat to settle
  hs.timer.usleep(10000)

  -- 3) Expand to target (size first, then move), then final snap
  setAXSizePos(w, {w = t.w, h = t.h}, nil)
  setAXSizePos(w, nil, {x = t.x, y = t.y})
  w:setFrame(t, 0)

  -- 4) One last verification nudge
  -- if not rectEq(w:frame(), t) then
  --   hs.timer.doAfter(0.02, function() w:setFrame(t, 0) end)
  -- end
end

-- Maximize using hammerspoon in case window exceed monitor dimensions, which Raycast can't handle
-- hs.hotkey.bind({"cmd", "ctrl"}, "o", FitToScreen)

----------------------------------------------------------------------
-- Swipe: Trackpad gestures
----------------------------------------------------------------------
hs.loadSpoon("Swipe")

local CYCLE_WORKSPACE_SCRIPT = os.getenv("HOME") .. "/dotfiles/aerospace/scripts/set-workspace.sh"
local function cycleWorkspace(cmd)
  hs.task.new("/bin/bash", nil, { "-lc", string.format("%q %s", CYCLE_WORKSPACE_SCRIPT, cmd) }):start()
end

-- Fire only once per swipe: remember the latest swipe id we acted on
local lastFiredId = nil
local threshold = 0.02  -- distance threshold before we consider it a “real” swipe

spoon.Swipe:start(4, function(direction, distance, id)
  if id == lastFiredId or distance < threshold then return end
  if direction == "left" then
    cycleWorkspace("next")
    lastFiredId = id
  elseif direction == "right" then
    cycleWorkspace("prev")
    lastFiredId = id
  end
end)


----------------------------------------------------------------------
-- ShiftIt: Window management
----------------------------------------------------------------------
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.ShiftIt = {
    url = "https://github.com/peterklijn/hammerspoon-shiftit",
    desc = "ShiftIt spoon repository",
    branch = "main",
}

spoon.SpoonInstall:andUse("ShiftIt", { repo = "ShiftIt" })
spoon.ShiftIt:bindHotkeys({})

-- Supercededed by Rectangle / Raycast
-- ----------------------------------------------------------------------
-- spoon.ShiftIt:bindHotkeys({
--     -- maximum = { { 'cmd', 'ctrl' }, 'o' },
--     -- left = { { 'cmd', 'ctrl' }, 'k' },
--     -- right = { { 'cmd', 'ctrl' }, ';' },
--     -- down = { { 'cmd', 'ctrl' }, 'l' },
--     -- up = { { 'cmd', 'alt', 'shift' }, 'o' },
--     -- upleft = { { 'cmd', 'alt', 'shift' }, 'k' },
--     -- upright = { { 'cmd', 'alt', 'shift' }, ';' },
--     -- botleft = { { 'cmd', 'alt', 'ctrl' }, 'k' },
--     -- botright = { { 'cmd', 'alt', 'ctrl' }, ';' },
--     -- center = { { 'cmd', 'alt', 'ctrl' }, 'c' },
--     -- nextScreen = { { 'cmd', 'alt' }, 'o' },
--     -- previousScreen = { { 'cmd', 'alt' }, 'l' },
--     -- toggleFullScreen = { { 'cmd', 'alt', 'ctrl' }, 'f' },
--     -- toggleZoom = { { 'cmd', 'alt', 'ctrl' }, 'z' },
--     -- resizeOut = { { 'cmd', 'alt', 'ctrl' }, '=' },
--     -- resizeIn = { { 'cmd', 'alt', 'ctrl' }, '-' }
--   })
-- ----------------------------------------------------------------------

-- -- Window hints
-- hs.hints.fontSize = 30
-- hs.hints.iconAlpha = 1.0
-- hs.hints.showTitleThresh = 0
-- hs.hints.hintChars = {'Q', 'W', 'E', 'A', 'S', 'D', 'Z', 'X', 'C', 'U', 'I', 'O', 'J', 'K', 'L', 'M', 'R', 'T', 'Y', 'F', 'G', 'H', 'V', 'B', 'N'}
-- hs.hotkey.bind({"cmd"}, "escape", function()
--     hs.hints.windowHints()
-- end)

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

----------------------------------------------------------------------
-- Move window to a specific space
----------------------------------------------------------------------

-- spoon.SpoonInstall.repos.Drag = {
--     url = "https://github.com/mogenson/Drag.spoon",
--     desc = "Drag spoon repository",
--     branch = "main",
-- }

-- spoon.SpoonInstall:andUse("Drag", { repo = "Drag" })

-- Drag = hs.loadSpoon("Drag")


-- figure out the space_id for the target space
-- > hs.spaces.allSpaces()
-- {
--   ["1E4625E7-5C5E-4DDC-B4C7-991CCCEF0732"] = { 1301 },
--   ["37D8832A-2D66-02CA-B9F7-8F30A301B230"] = { 528, 2, 1306 }
-- }
-- eg. 1306 is the third space on the second screen
-- > Drag:focusedWindowToSpace(1306)

-- -- Function to get spaceId by space name
-- function getSpaceIdByName(spaceName)
--     local spaceNames = hs.spaces.missionControlSpaceNames()
--     for _, desktops in pairs(spaceNames) do
--         for index, name in pairs(desktops) do
--             if name == spaceName then
--                 return index
--             end
--         end
--     end
--     return nil
-- end

-- -- Function to move focused window to a specific space
-- function moveFocusedWindowToSpace(spaceNumber)
--     print ("Moving focused window to space " .. spaceNumber)
--     local spaceName = "Desktop " .. spaceNumber
--     local spaceId = getSpaceIdByName(spaceName)
--     if spaceId then
--         local focusedWindow = hs.window.focusedWindow()
--         if focusedWindow then
--             print(focusedWindow)
--             print(spaceId)
--             Drag.focusedWindowToSpace(spaceId)
--             -- print(hs.spaces.moveWindowToSpace(focusedWindow:id(), spaceId))
--         else
--             hs.alert.show("No focused window")
--         end
--     else
--         hs.alert.show("Space not found: " .. spaceName)
--     end
-- end

-- -- Bind keys cmd + shift + 1-6
-- for i = 1, 6 do
--     hs.hotkey.bind({"cmd", "shift"}, tostring(i), function()
--         moveFocusedWindowToSpace(i)
--     end)
-- end

----------------------------------------------------------------------
-- restore-spaces
-- https://github.com/tplobo/restore-spaces
----------------------------------------------------------------------
-- hs.hotkey = require "hs.hotkey"
-- hs.restore_spaces = require 'hs.restore_spaces.restore_spaces'

-- -- Configure 'restore_spaces'
-- hs.restore_spaces.verbose = false
-- hs.restore_spaces.space_pause = 0.3
-- hs.restore_spaces.screen_pause = 0.4

-- -- Bind hotkeys for 'restore_spaces'
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "S", hs.restore_spaces.saveEnvironmentState)
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", hs.restore_spaces.applyEnvironmentState)

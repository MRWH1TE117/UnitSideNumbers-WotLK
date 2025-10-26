-- UnitSideNumbers (WotLK 3.3.5a) — v1.7.1
-- • Stabilne warstwy, kolor poziomu (RANGE/CLASS/STATIC)
-- • Płynne aktualizacje z OnValueChanged
-- • Trunkowanie zamiast zaokrąglania (18.9k ≠ 19k), %HP bez podbijania
-- NOWE: Poprawka aktualizacji wyświetlania wartości dla pustego targetu i focusa

local cfg = {
  font = "Fonts\\FRIZQT__.TTF",
  size = 10,
  outline = "OUTLINE",
  spacing = -2,
  offset = -2,
  width = 120,
  height = 40,
  percentYOffset = 2,
  holderFrameLevelBoost = 12,
  levelOffsetX = -10,
  levelOffsetY = -17,
}

UnitSideNumbers_Strata     = UnitSideNumbers_Strata     or "MEDIUM"
UnitSideNumbers_LevelMode  = UnitSideNumbers_LevelMode  or "RANGE"
UnitSideNumbers_LevelColor = UnitSideNumbers_LevelColor or {1,1,1}

local function colorByLevelRange(lvl)
  if not lvl or lvl <= 0 then return 1,1,1 end
  if lvl <= 19 then return 0.7,0.7,0.7
  elseif lvl <= 39 then return 1,1,1
  elseif lvl <= 59 then return 0.5,0.8,1
  elseif lvl <= 69 then return 1,0.65,0.2
  elseif lvl <= 79 then return 0.3,1,0.3
  else return 1,1,0.2
  end
end

-- TRUNKOWANIE (nie zaokrąglamy w górę)
local function short(n)
  if not n then return "0" end
  if n >= 1000000 then
    local x = math.floor(n / 100000) / 10   -- 1 dziesiętna, ucięta
    local s = string.format("%.1fm", x)
    return (s:gsub("%.0m","m"))
  elseif n >= 1000 then
    local x = math.floor(n / 100) / 10      -- 1 dziesiętna, ucięta
    local s = string.format("%.1fk", x)
    return (s:gsub("%.0k","k"))
  end
  return tostring(math.floor(n + 0.0))
end

local function makeBlock(anchorFrame, side, justify)
  local holder = CreateFrame("Frame", nil, UIParent)
  holder:SetFrameStrata(UnitSideNumbers_Strata or "MEDIUM")
  holder:SetFrameLevel((anchorFrame:GetFrameLevel() or 0) + (cfg.holderFrameLevelBoost or 12))
  holder:SetSize(cfg.width, cfg.height)

  if side == "RIGHT" then
    holder:SetPoint("LEFT", anchorFrame, "RIGHT", cfg.offset, 0)
  else
    holder:SetPoint("RIGHT", anchorFrame, "LEFT", -cfg.offset, 0)
  end

  holder.lines = {}
  for i=1,3 do
    local fs = holder:CreateFontString(nil, "OVERLAY")
    fs:SetFont(cfg.font, cfg.size, cfg.outline)
    fs:SetJustifyH(justify)
    fs:SetNonSpaceWrap(false)
    fs:SetWordWrap(false)
    fs:SetWidth(cfg.width)
    if i == 1 then
      fs:SetPoint("TOP", holder, "TOP", 0, cfg.percentYOffset)
    else
      fs:SetPoint("TOP", holder.lines[i-1], "BOTTOM", 0, cfg.spacing)
    end
    holder.lines[i] = fs
  end
  return holder
end

local fmtUnit

local function attachHideShow(frame, unit, block)
  if not frame or not block then return end

  -- jeśli frame już jest ukryty – wyczyść teksty od razu
  if not frame:IsShown() then
    for i=1,3 do block.lines[i]:SetText("") end
  end

  frame:HookScript("OnHide", function()
    for i=1,3 do block.lines[i]:SetText("") end
  end)

  frame:HookScript("OnShow", function()
    if UnitExists(unit) then
      if fmtUnit then fmtUnit(unit, block) end
    else
      for i=1,3 do block.lines[i]:SetText("") end
    end
  end)
end



local frames = { player=nil, target=nil, focus=nil }
local levelHolder, levelFS

local function ensureFrames()
  if not frames.player and PlayerFrame then
    frames.player = makeBlock(PlayerFrame, "RIGHT", "LEFT")
  end
  if not frames.target and TargetFrame then
    frames.target = makeBlock(TargetFrame, "LEFT", "RIGHT")
	attachHideShow(TargetFrame, "target", frames.target)
  end
  if not frames.focus and FocusFrame then
    frames.focus  = makeBlock(FocusFrame, "LEFT", "RIGHT")
	attachHideShow(FocusFrame, "focus", frames.focus)
  end
  if not levelHolder and PlayerFrame then
    levelHolder = CreateFrame("Frame", nil, UIParent)
    levelHolder:SetFrameStrata(UnitSideNumbers_Strata or "MEDIUM")
    levelHolder:SetFrameLevel((PlayerFrame:GetFrameLevel() or 0) + (cfg.holderFrameLevelBoost or 12))
    levelHolder:SetSize(40, 16)
    levelHolder:SetPoint("TOPRIGHT", PlayerFrame, "TOPRIGHT", cfg.levelOffsetX, cfg.levelOffsetY)

    levelFS = levelHolder:CreateFontString(nil, "OVERLAY")
    levelFS:SetFont(cfg.font, cfg.size, "")
    levelFS:SetJustifyH("RIGHT")
    levelFS:SetPoint("RIGHT", levelHolder, "RIGHT", 0, 0)
    levelFS:SetText("")
  end
end

local function colorLevel()
  if not levelFS then return end
  local mode = (UnitSideNumbers_LevelMode or "RANGE"):upper()
  if mode == "STATIC" then
    local c = UnitSideNumbers_LevelColor or {1,1,1}
    levelFS:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1)
  elseif mode == "CLASS" then
    local _, engClass = UnitClass("player")
    local col = RAID_CLASS_COLORS and RAID_CLASS_COLORS[engClass]
    if col then levelFS:SetTextColor(col.r, col.g, col.b) else levelFS:SetTextColor(1,1,1) end
  else
    local lvl = UnitLevel("player")
    local r,g,b = colorByLevelRange(lvl)
    levelFS:SetTextColor(r,g,b)
  end
end

-- ======== PŁYNNE aktualizacje z pasków =========
local function updateFromBar(unit, block, isHealth, val, minV, maxV)
  if not block then return end

  -- jeśli unit nie istnieje, wyczyść linie i wyjdź
  if not UnitExists(unit) then
    for i=1,3 do block.lines[i]:SetText("") end
    return
  end

  maxV = maxV or 0
  val  = val or 0

  if isHealth then
    local pct = (maxV > 0) and math.floor((val / maxV) * 100) or 0
    if pct > 100 then pct = 100 end
    block.lines[1]:SetText(pct .. "%")
    block.lines[2]:SetText(short(val) .. " / " .. short(maxV))
  else
    if maxV > 0 then
      block.lines[3]:SetText(short(val) .. " / " .. short(maxV))
    else
      block.lines[3]:SetText("")
    end
  end
end


local function hookBar(bar, unit, block, isHealth)
  if not bar or not block or bar.__usnHooked then return end
  bar.__usnHooked = true
  bar:HookScript("OnValueChanged", function(self, v)
    local minV, maxV = self:GetMinMaxValues()
    updateFromBar(unit, block, isHealth, v, minV, maxV)
  end)
  -- na zmianę maksymalnej wartości (np. formy, buffy)
  if not bar.__usnMMVHooked then
    bar.__usnMMVHooked = true
    hooksecurefunc(bar, "SetMinMaxValues", function(self, minV, maxV)
      local v = self:GetValue()
      updateFromBar(unit, block, isHealth, v, minV, maxV)
    end)
  end
end

local function hookAllBars()
  ensureFrames()
  hookBar(_G.PlayerFrameHealthBar, "player", frames.player, true)
  hookBar(_G.PlayerFrameManaBar,   "player", frames.player, false)
  hookBar(_G.TargetFrameHealthBar, "target", frames.target, true)
  hookBar(_G.TargetFrameManaBar,   "target", frames.target, false)
  if _G.FocusFrame then
    hookBar(_G.FocusFrameHealthBar, "focus", frames.focus, true)
    hookBar(_G.FocusFrameManaBar,   "focus", frames.focus, false)
  end
end
-- ==============================================

fmtUnit = function(unit, block)
  if not block or not UnitExists(unit) then
    if block then for i=1,3 do block.lines[i]:SetText("") end end
    return
  end
  local hp, hpMax = UnitHealth(unit) or 0, UnitHealthMax(unit) or 1
  local pct = (hpMax > 0) and math.floor((hp/hpMax)*100) or 0
  if pct > 100 then pct = 100 end
  local pow, powMax = UnitPower(unit) or 0, UnitPowerMax(unit) or 0

  block.lines[1]:SetText(pct.."%")
  block.lines[2]:SetText(short(hp).." / "..short(hpMax))
  if powMax > 0 then
    block.lines[3]:SetText(short(pow).." / "..short(powMax))
  else
    block.lines[3]:SetText("")
  end
end

local function refreshAll()
  ensureFrames()
  hookAllBars()
  fmtUnit("player", frames.player)
  fmtUnit("target", frames.target)
  fmtUnit("focus",  frames.focus)
  if levelFS then
    local lvl = UnitLevel("player") or ""
    levelFS:SetText(lvl ~= "" and tostring(lvl) or "")
    colorLevel()
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PLAYER_FOCUS_CHANGED")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_MAXHEALTH")
f:RegisterEvent("UNIT_POWER")
f:RegisterEvent("UNIT_MAXPOWER")
f:RegisterEvent("UNIT_DISPLAYPOWER")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:SetScript("OnEvent", function(_, evt, unit)
  if evt == "PLAYER_ENTERING_WORLD" then
    local t=0 local d=CreateFrame("Frame")
    d:SetScript("OnUpdate", function(_,e)
      t=t+e
      if t>=0.1 then
        d:SetScript("OnUpdate", nil)
        refreshAll()
      end
    end)
    return
  end
  if evt == "PLAYER_LEVEL_UP" then
    if levelFS then
      local lvl = UnitLevel("player") or ""
      levelFS:SetText(lvl ~= "" and tostring(lvl) or "")
      colorLevel()
    end
    return
  end
  if evt == "PLAYER_TARGET_CHANGED" or evt == "PLAYER_FOCUS_CHANGED" then
    refreshAll(); return
  end
  if unit == "player" then
    fmtUnit("player", frames.player)
  elseif unit == "target" then
    fmtUnit("target", frames.target)
  elseif unit == "focus" then
    fmtUnit("focus", frames.focus)
  end
end)

SLASH_USN1 = "/usn"
SlashCmdList["USN"] = function(msg)
  msg = (msg or ""):lower()
  if msg == "reset" then
    if frames.player then frames.player:ClearAllPoints(); frames.player:SetPoint("LEFT",  PlayerFrame, "RIGHT", cfg.offset, 0) end
    if frames.target then frames.target:ClearAllPoints(); frames.target:SetPoint("RIGHT", TargetFrame, "LEFT", -cfg.offset, 0) end
    if frames.focus  then frames.focus :ClearAllPoints(); frames.focus :SetPoint("RIGHT", FocusFrame , "LEFT", -cfg.offset, 0) end
    if levelHolder then levelHolder:ClearAllPoints(); levelHolder:SetPoint("TOPRIGHT", PlayerFrame, "TOPRIGHT", cfg.levelOffsetX, cfg.levelOffsetY) end
    print("|cff00ff96[UnitSideNumbers]|r reset pos")

  elseif msg:match("^strata") then
    local s = msg:match("^strata%s+(%S+)") s = s and s:upper()
    if s == "LOW" or s == "MEDIUM" or s == "HIGH" then
      UnitSideNumbers_Strata = s
      for _,blk in pairs(frames) do if blk then blk:SetFrameStrata(s) end end
      if levelHolder then levelHolder:SetFrameStrata(s) end
      print("|cff00ff96[UnitSideNumbers]|r strata = "..s)
    else
      print("|cff00ff96[UnitSideNumbers]|r użycie: /usn strata LOW|MEDIUM|HIGH")
    end

  elseif msg:match("^lvlcolor") then
    local m = msg:match("^lvlcolor%s+(%S+)")
    if m then
      m = m:lower()
      if m == "range" or m == "class" or m == "static" or m == "diff" then
        UnitSideNumbers_LevelMode = (m == "diff") and "DIFFTARGET" or (m == "class" and "CLASS" or (m=="static" and "STATIC" or "RANGE"))
        colorLevel()
        print("|cff00ff96[UnitSideNumbers]|r lvlcolor = "..UnitSideNumbers_LevelMode)
      else
        print("|cff00ff96[UnitSideNumbers]|r użycie: /usn lvlcolor range|class|static")
      end
    else
      print("|cff00ff96[UnitSideNumbers]|r lvlcolor = "..(UnitSideNumbers_LevelMode or "RANGE"))
    end

  elseif msg:match("^lvlrgb") then
    local r,g,b = msg:match("^lvlrgb%s+([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)")
    r,g,b = tonumber(r), tonumber(g), tonumber(b)
    if r and g and b then
      UnitSideNumbers_LevelColor = { math.max(0,math.min(1,r)), math.max(0,math.min(1,g)), math.max(0,math.min(1,b)) }
      if (UnitSideNumbers_LevelMode or "RANGE") == "STATIC" then colorLevel() end
      print(string.format("|cff00ff96[UnitSideNumbers]|r lvlrgb set: %.2f %.2f %.2f", UnitSideNumbers_LevelColor[1],UnitSideNumbers_LevelColor[2],UnitSideNumbers_LevelColor[3]))
    else
      print("|cff00ff96[UnitSideNumbers]|r użycie: /usn lvlrgb R G B   (0..1)")
    end

  else
    print("|cff00ff96[UnitSideNumbers]|r komendy: reset | strata LOW|MEDIUM|HIGH | lvlcolor range|class|static | lvlrgb R G B")
  end
end

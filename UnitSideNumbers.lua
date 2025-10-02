-- UnitSideNumbers (WotLK 3.3.5a) — v1.5
-- • Stabilne warstwy (strata/level) dla linii, by nic nie chowało %HP
-- • Kolor poziomu wg zakresu (RANGE: 70-79 zielony, 80 żółty, itd.)

local cfg = {
  font = "Fonts\\FRIZQT__.TTF",
  size = 10,
  outline = "OUTLINE",
  spacing = -2,       -- odstęp między liniami 2 i 3
  offset = -2,         -- odległość bloku od ramki
  width = 120,
  height = 40,
  percentYOffset = 2, -- %HP (linia 1) lekko wyżej
  holderFrameLevelBoost = 12, -- o ile podnieść ponad ramkę Blizz
  -- Poziom gracza (po prawej od góry PlayerFrame)
  levelOffsetX = -10,
  levelOffsetY = -17,
}

-- zapamiętywane między /reload
UnitSideNumbers_Strata     = UnitSideNumbers_Strata     or "MEDIUM"
UnitSideNumbers_LevelMode  = UnitSideNumbers_LevelMode  or "RANGE" -- RANGE | CLASS | STATIC
UnitSideNumbers_LevelColor = UnitSideNumbers_LevelColor or {1,1,1} -- dla STATIC

-- Kolory dla trybu RANGE
local function colorByLevelRange(lvl)
  if not lvl or lvl <= 0 then return 1,1,1 end
  if lvl <= 19 then return 0.7,0.7,0.7      -- szary
  elseif lvl <= 39 then return 1,1,1        -- biały
  elseif lvl <= 59 then return 0.5,0.8,1    -- jasnoniebieski
  elseif lvl <= 69 then return 1,0.65,0.2   -- pomarańcz
  elseif lvl <= 79 then return 0.3,1,0.3    -- zielony
  else return 1,1,0.2                       -- 80 = żółty
  end
end

local function short(n)
  if not n then return "0" end
  if n >= 1e6 then return (string.format("%.1fm", n/1e6)):gsub("%.?0m","m") end
  if n >= 1e3 then return (string.format("%.1fk", n/1e3)):gsub("%.?0k","k") end
  return tostring(n)
end

-- Tworzy niezależny holder (rodzic = UIParent) i kotwiczy do ramki Blizz,
-- żeby strata/level nie były ograniczane przez oryginalną ramkę.
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

local frames = { player=nil, target=nil, focus=nil }
local levelHolder, levelFS -- osobny holder dla poziomu (stabilne warstwy)

local function ensureFrames()
  if not frames.player and PlayerFrame then
    frames.player = makeBlock(PlayerFrame, "RIGHT", "LEFT")
  end
  if not frames.target and TargetFrame then
    frames.target = makeBlock(TargetFrame, "LEFT", "RIGHT")
  end
  if not frames.focus and FocusFrame then
    frames.focus  = makeBlock(FocusFrame, "LEFT", "RIGHT")
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
    return
  elseif mode == "CLASS" then
    local _, engClass = UnitClass("player")
    local col = RAID_CLASS_COLORS and RAID_CLASS_COLORS[engClass]
    if col then levelFS:SetTextColor(col.r, col.g, col.b); return end
    levelFS:SetTextColor(1,1,1); return
  else -- RANGE (domyślnie)
    local lvl = UnitLevel("player")
    local r,g,b = colorByLevelRange(lvl)
    levelFS:SetTextColor(r,g,b)
    return
  end
end

local function fmtUnit(unit, block)
  if not block or not UnitExists(unit) then
    if block then for i=1,3 do block.lines[i]:SetText("") end end
    return
  end
  local hp, hpMax = UnitHealth(unit) or 0, UnitHealthMax(unit) or 1
  local p = (hpMax > 0) and math.floor((hp/hpMax)*100 + 0.5) or 0
  local pow, powMax = UnitPower(unit) or 0, UnitPowerMax(unit) or 0
  local hasPower = (powMax and powMax > 0)

  block.lines[1]:SetText(p.."%")
  block.lines[2]:SetText(short(hp).." / "..short(hpMax))
  if hasPower then
    block.lines[3]:SetText(short(pow).." / "..short(powMax))
  else
    block.lines[3]:SetText("")
  end
end

local function refreshAll()
  ensureFrames()
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
    d:SetScript("OnUpdate", function(_,e) t=t+e if t>=0.1 then d:SetScript("OnUpdate", nil) refreshAll() end end)
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

-- Komendy: reset / strata / tryb kolorowania / statyczny kolor
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

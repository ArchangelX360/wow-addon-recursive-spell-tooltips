local function QueryAvailableSpells()
    print("[RecursiveSpellTooltip] Querying spells...")
    local spells = {}
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
        local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
        for j = offset + 1, offset + numSlots do
            local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
            local spellType, id, name = spellBookItemInfo.itemType, spellBookItemInfo.spellID, spellBookItemInfo.name
            if spellType == Enum.SpellBookItemType.Spell then
                table.insert(spells, { id = id, name = name })
            end
        end
    end
    return spells
end

local function GetSelectedTalents()
    print("[RecursiveSpellTooltip] Querying talents...")
    local talents = {}
    local configID = C_ClassTalents.GetActiveConfigID()
    local configInfo = C_Traits.GetConfigInfo(configID)
    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            if nodeInfo and nodeInfo.activeEntry then
                local entryID = nodeInfo.activeEntry.entryID
                local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                if entryInfo.definitionID then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    local spellInfos = C_Spell.GetSpellInfo(definitionInfo.spellID)
                    table.insert(talents, {id = spellInfos.spellID, name = spellInfos.name})
                end
            end
        end
    end
    return talents
end

function string.mentions(self, spellName)
    return self:find("^" .. spellName .. " ") ~= nil
            or self:find("^" .. spellName .. ",") ~= nil
            or self:find(" " .. spellName .. " ") ~= nil
            or self:find(" " .. spellName .. ",") ~= nil
            or self:find(" " .. spellName .. ".") ~= nil
end

-- TODO: preprocess that and cache it
local function ListMentionedSpells(allSpells, spellId)
    local mentioned = {}
    local description = C_Spell.GetSpellDescription(spellId) -- must be populated when `SPELL_TEXT_UPDATE` triggers on the spell ID
    for _, spell in ipairs(allSpells) do
        if tonumber(spell.id) ~= tonumber(spellId) and not mentioned[spell.id] then
            if description:mentions(spell.name) then
                description = description:gsub(spell.name, "")
                table.insert(mentioned, spell.id)
            end
        end
    end
    return mentioned
end

local function ShowSpellTooltip(availableFrames, spellID, parentSpellId, parentTooltip, hoveredSpellTooltip)
    local f = availableFrames[spellID .. "" .. parentSpellId]
    if not f then
        f = CreateFrame("GameTooltip", "RecursiveSpellTooltip" .. spellID .. "" .. parentSpellId, parentTooltip, "GameTooltipTemplate")
        availableFrames[spellID .. "" .. parentSpellId] = f
    end
    f:SetOwner(parentTooltip, "ANCHOR_NONE")
    if hoveredSpellTooltip == parentTooltip then
        f:SetScale(0.7)
        f:SetPoint("TOPRIGHT", parentTooltip, "TOPLEFT")
    else
        f:SetScale(1)
        f:SetPoint("TOP", parentTooltip, "BOTTOM")
    end
    f:SetSpellByID(spellID)
    f:Show()
    return f
end

local spellsAndTalents = {}
local eventHandlerFrame = CreateFrame("Frame")
eventHandlerFrame:RegisterEvent("PLAYER_LOGIN")
eventHandlerFrame:RegisterEvent("SPELLS_CHANGED")
eventHandlerFrame:SetScript("OnEvent", function(self, event)
    print("[RecursiveSpellTooltip] Refreshing spells and talents...")
    spellsAndTalents = {}
    local spells = QueryAvailableSpells()
    print("[RecursiveSpellTooltip] Found " .. table.getn(spells) .. " spells")
    local talents = GetSelectedTalents()
    print("[RecursiveSpellTooltip] Found " .. table.getn(talents) .. " talents")
    for _, v in ipairs(spells) do
        table.insert(spellsAndTalents, v)
    end
    for _, v in ipairs(talents) do
        table.insert(spellsAndTalents, v)
    end
    table.sort(spellsAndTalents, function (a, b)
        return string.len(a.name) > string.len(b.name)
    end)
end)

local frames = {}

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function (tooltip, data)
    local spellID = data.id
    if spellID then
        tooltip:Show()
        local mentioned = ListMentionedSpells(spellsAndTalents, spellID)
        local mentioned_tooltips = {}
        local parent = tooltip
        for _, mentionedSpellId in ipairs(mentioned) do
            local other = ShowSpellTooltip(frames, mentionedSpellId, spellId, parent, tooltip)
            parent = other
            table.insert(mentioned_tooltips, other)
        end
    end
end)

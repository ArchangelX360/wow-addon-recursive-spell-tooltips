local function QueryAvailableSpells()
    print("Querying spells...")
    local spells = {}
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    	local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
    	local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
    	for j = offset+1, offset+numSlots do
    		local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
    		local spellType, id, name = spellBookItemInfo.itemType, spellBookItemInfo.spellID, spellBookItemInfo.name
            if spellType == Enum.SpellBookItemType.Spell then
                table.insert(spells, {id = id, name = name})
            end
    	end
    end
    return spells
end

local function GetSelectedTalents()
    print("Querying talents...")
    local talents = {}
    local configID = C_ClassTalents.GetActiveConfigID()
    local configInfo = C_Traits.GetConfigInfo(configID)
    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            if nodeInfo then
                if nodeInfo.activeEntry then
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
    end
    return talents
end

local function sortByDescreasingLength(a, b)
    return string.len(a.name) > string.len(b.name)
end

spells = QueryAvailableSpells()
print("Found " .. table.getn(spells) .. " spells")
talents = GetSelectedTalents()
print("Found " .. table.getn(talents) .. " talents")
spellsAndTalents = {}
for _,v in ipairs(spells) do
    table.insert(spellsAndTalents, v)
end
for _,v in ipairs(talents) do
    table.insert(spellsAndTalents, v)
end
table.sort(spellsAndTalents, sortByDescreasingLength)

local function mentions(description, needle)
    return description:find("^"..needle.." ") ~= nil 
      or description:find("^"..needle..",") ~= nil
      or description:find(" "..needle.." ") ~= nil
      or description:find(" "..needle..",")
      or description:find(" "..needle..".") ~= nil
end

-- TODO: preprocess that and cache it
local function listMentionedSpells(spellId)
    -- print("Querying mentioned spells of ".. spellId)
    local mentioned = {}
    local description = C_Spell.GetSpellDescription(spellId) -- must be populated when `SPELL_TEXT_UPDATE` triggers on the spell ID
    for _, spell in ipairs(spellsAndTalents) do
        if tonumber(spell.id) ~= tonumber(spellId) and not mentioned[spell.id] then
            if mentions(description, spell.name) then
                description = description:gsub(spell.name, "")
                table.insert(mentioned, spell.id)
            end
        end
    end
    return mentioned
end

local function addCustomSpellTooltip(tooltip, data)
    local spellID = data.id
    if not spellID then return end
    tooltip:Show()

    local mentioned = listMentionedSpells(spellID)
    local mentioned_tooltips = {}
    local parent = tooltip
    for _, m in ipairs(mentioned) do
        local other = ShowSpellTooltip(m, parent, parent == tooltip)
        parent = other
        table.insert(mentioned_tooltips, other)
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, addCustomSpellTooltip)

local frames = {}

function ShowSpellTooltip(spellID, parent, isFirst)
    local f = frames[spellID]
    if not f then
        f = CreateFrame("GameTooltip", "RecursiveSpellTooltip"..spellID, parent, "GameTooltipTemplate")
        frames[spellID] = f
    end
    f:SetOwner(parent, "ANCHOR_NONE")
    if isFirst then
        f:SetPoint("TOPRIGHT", parent, "TOPLEFT")
    else
        f:SetPoint("TOP", parent, "BOTTOM")
    end
    f:SetSpellByID(spellID)
    f:Show()
    return f
end


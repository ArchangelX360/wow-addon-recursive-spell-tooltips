local function QueryAvailableSpells()
    print("Querying spells...")
    local spells = {}
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    	local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
    	local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
    	for j = offset+1, offset+numSlots do
    		local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
    		local spellType, id, name = spellBookItemInfo.itemType, spellBookItemInfo.spellID, spellBookItemInfo.name
            if spellType == Enum.SpellBookItemType.Spell and IsSpellKnown(id) then
                --print("Found spell " .. name .. "(" .. id .. ")")
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
            if nodeInfo and nodeInfo.currentRank > 0 then
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

spells = QueryAvailableSpells()
print("Found " .. table.getn(spells) .. " spells")
talents = GetSelectedTalents()
print("Found " .. table.getn(talents) .. " talents")

-- TODO: preprocess that and cache it
local function listMentionedSpells(spellId)
    print("Querying mentioned spells of ".. spellId)
    local mentioned = {}
    local description = C_Spell.GetSpellDescription(spellId) -- must be populated when `SPELL_TEXT_UPDATE` triggers on the spell ID
    for _, spell in ipairs(spells) do
        sIndex = string.find(description, spell.name)
        if sIndex and spell.id ~= spellId then
            table.insert(mentioned, spell.id)
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
    for _, m in ipairs(mentioned) do
        local other = ShowSpellTooltip(m, tooltip)
        table.insert(mentioned_tooltips, other)
    end

    local originalOnHide = tooltip:GetScript("OnHide")
    local function OnTooltipHide()
        for _, other in ipairs(mentioned) do
            other:Hide() -- TODO: hide each of them, full bug for now
        end
        if originalOnHide then
            originalOnHide()
        end
    end
    tooltip:SetScript("OnHide", OnTooltipHide)
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, addCustomSpellTooltip)

-- TODO: need to have frames dynamically, so that we can display many tooltips

local MyTooltipFrame = CreateFrame("GameTooltip", "MyTooltip", UIParent, "GameTooltipTemplate")

function ShowSpellTooltip(spellID, parent)
    local p
    if parent then
        p = parent
    else
        p = UIParent
    end
    MyTooltipFrame:SetOwner(p, "ANCHOR_RIGHT")
    MyTooltipFrame:SetSpellByID(spellID)
    MyTooltipFrame:Show()
    return MyTooltipFrame
end


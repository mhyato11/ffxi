-- License: BSD 3-Clause (see bottom of file)
-- Copyright (c) 2026 The Continuum

-- abbyproc - Element / Weapon / WS cycler with HUD

_addon.name     = 'abbyproc'
_addon.author   = 'The Continuum'
_addon.version  = '2.0'
_addon.commands = { 'aproc' }

local texts = require('texts')

-------------------------------------------------------------
--  LOAD SETTINGS
-------------------------------------------------------------
local addon_path = windower.addon_path
local user_settings = dofile(addon_path .. 'data/settings.lua')

-------------------------------------------------------------
--  KEYBINDS (loaded from data/settings.lua)
-------------------------------------------------------------
local key_element = user_settings.key_element or 'f10'
local key_weapon  = user_settings.key_weapon or 'f11'
local key_ws      = user_settings.key_ws or 'f12'

-------------------------------------------------------------
--  WEAPONS (loaded from data/settings.lua)
-------------------------------------------------------------
local weapon_groups = {}
local char_name = windower.ffxi.get_player() and windower.ffxi.get_player().name or nil

for wtype, weapon in pairs(user_settings.weapons) do
    weapon_groups[wtype] = { weapon }
end

if char_name and user_settings.weapons_per_character and user_settings.weapons_per_character[char_name] then
    for wtype, weapon in pairs(user_settings.weapons_per_character[char_name]) do
        weapon_groups[wtype] = { weapon }
    end
end

-------------------------------------------------------------
--  ELEMENT → (WEAPON TYPE, WEAPONSKILL) MAPPING
--  From the Abyssea red proc table.
-------------------------------------------------------------
local element_order = {
    "Fire",
	"Ice",
	"Wind",
	"Earth",
	"Thunder",
	"Light",
    "Dark",
    "Kill",
}

local element_map = {
    Wind = {
        {weapon_type = "Dagger",       ws = "Cyclone"},
        {weapon_type = "Great Katana", ws = "Tachi: Jinpu"},
    },
    Dark = {
        {weapon_type = "Dagger",  ws = "Energy Drain"},
        {weapon_type = "Scythe",  ws = "Shadow of Death"},
        {weapon_type = "Katana",  ws = "Blade: Ei"},
    },
    Fire = {
        {weapon_type = "Sword", ws = "Red Lotus Blade"},
    },
    Light = {
        {weapon_type = "Sword",        ws = "Seraph Blade"},
        {weapon_type = "Great Katana", ws = "Tachi: Koki"},
        {weapon_type = "Club",         ws = "Seraph Strike"},
        {weapon_type = "Staff",        ws = "Sunburst"},
    },
    Ice = {
        {weapon_type = "Great Sword", ws = "Freezebite"},
    },
    Thunder = {
        {weapon_type = "Polearm", ws = "Raiden Thrust"},
    },
    Earth = {
        {weapon_type = "Staff", ws = "Earth Crusher"},
    },
}

-------------------------------------------------------------
--  ELEMENT COLORS (RGB) 
-------------------------------------------------------------
local element_colors = {
    Light   = {255, 255, 255}, -- LGT
    Fire    = {255,  64,  64}, -- FIR
    Wind    = {  0, 255,   0}, -- WND
    Thunder = {180,   0, 255}, -- THD
    Dark    = { 80,  60, 100}, -- DRK
    Ice     = {128, 255, 255}, -- ICE
    Earth   = {165, 100,  40}, -- STN
    Water   = { 64, 128, 255}, -- WTR (unused)
    Kill    = {255, 200,   0}, -- KILL (gold)
}

-------------------------------------------------------------
--  INTERNAL STATE
-------------------------------------------------------------
local current_element_index = 1
local current_element       = element_order[current_element_index]

local weapons_for_element   = {} 
local current_weapon_index  = 0

local kill_weapon = user_settings.kill_weapon or "Naegling"
local kill_sub = user_settings.kill_sub or "Blurred Shield +1"
local kill_ws = user_settings.kill_ws or "Savage Blade"
local kill_enabled = true

-- Per-character kill override
if char_name and user_settings.kill_per_character and user_settings.kill_per_character[char_name] then
    local char_kill = user_settings.kill_per_character[char_name]
    if char_kill.kill_weapon == false then
        kill_enabled = false
    else
        kill_weapon = char_kill.kill_weapon or kill_weapon
        kill_sub = char_kill.kill_sub or kill_sub
        kill_ws = char_kill.kill_ws or kill_ws
    end
end

-------------------------------------------------------------
--  TEXT BOX (HUD)
-------------------------------------------------------------
local info_box = texts.new()
info_box:pos(user_settings.hud_x or 800, user_settings.hud_y or 400)
info_box:size(12)
info_box:bold(true)
info_box:show()
info_box:bg_alpha(180)  
info_box:bg_color(30, 30, 30) 

local function colorize_element(name)
    local c = element_colors[name] or {255, 255, 255}
    return string.format('\\cs(%d,%d,%d)%s\\cr', c[1], c[2], c[3], name or 'None')
end

local function update_display()
    local elem_str = colorize_element(current_element or 'None')

    local weapon_type = 'None'
    local wsname      = 'None'

    local entry = weapons_for_element[current_weapon_index]
    if entry then
        weapon_type = entry.weapon_type or 'None'
        wsname      = entry.ws or 'None'
    end

    local text
    if current_element == "Kill" then
        text = string.format(
[[\cs(200,200,200)[AbysseaProc]\cr
\cs(160,160,160)Mode:\cr      %s
\cs(160,160,160)Weapon:\cr    %s / %s
\cs(160,160,160)WS:\cr        %s]],
            elem_str,
            kill_weapon,
            kill_sub,
            kill_ws
        )
    else
        local kill_color = element_colors['Kill'] or {255, 200, 0}
        local kill_str = string.format('\\cs(%d,%d,%d)%s\\cr', kill_color[1], kill_color[2], kill_color[3], kill_weapon)
        text = string.format(
[[\cs(200,200,200)[AbysseaProc]\cr
\cs(160,160,160)Element:\cr   %s
\cs(160,160,160)Weapon:\cr    %s
\cs(160,160,160)WS:\cr        %s
\cs(160,160,160)Kill:\cr       %s]],
            elem_str,
            weapon_type,
            wsname,
            kill_str
        )
    end

    info_box:text(text)
    info_box:show()
end


-------------------------------------------------------------
--  BUILD LIST OF ACTUAL WEAPONS FOR CURRENT ELEMENT
-------------------------------------------------------------
local function rebuild_weapons_for_element()
    weapons_for_element = {}
    current_weapon_index = 0

    local elem = current_element
    local elem_data = element_map[elem]
    if not elem_data then
        update_display()
        return
    end

    for _, entry in ipairs(elem_data) do
        local wtype  = entry.weapon_type
        local wsname = entry.ws
        local list   = weapon_groups[wtype]

        if list then
            for _, weapon in ipairs(list) do
                table.insert(weapons_for_element, {
                    weapon_type = wtype,
                    weapon_name = weapon.main,
                    weapon_sub  = weapon.sub,
                    ws          = wsname,
                })
            end
        end
    end

    update_display()
end

-------------------------------------------------------------
--  CYCLE ELEMENT
-------------------------------------------------------------
local function cycle_element()
    current_element_index = current_element_index + 1
    -- Skip Kill mode if kill is disabled
    if current_element_index > #element_order or (element_order[current_element_index] == "Kill" and not kill_enabled) then
        current_element_index = 1
    end

    current_element = element_order[current_element_index]

    -- Kill weapon mode
    if current_element == "Kill" then
        windower.send_command('input /equip main "' .. kill_weapon .. '";input /equip sub "' .. kill_sub .. '"')
        windower.send_command('gs c autows ' .. kill_ws)
        windower.send_command('gs c set AutoWSMode true')
        windower.add_to_chat(207,
            string.format("[AbysseaProc] Kill mode: %s / %s", kill_weapon, kill_sub)
        )
        weapons_for_element = {}
        current_weapon_index = 0
        update_display()
        return
    end

    rebuild_weapons_for_element()

    windower.add_to_chat(207,
        string.format("[AbysseaProc] Element: %s", current_element)
    )

    -- Auto-equip and set autows for fishing
    if #weapons_for_element == 1 then
        current_weapon_index = 1
        local entry = weapons_for_element[current_weapon_index]
        windower.send_command('input /equip main "' .. entry.weapon_name .. '";input /equip sub "' .. entry.weapon_sub .. '"')
        windower.send_command('gs c autows ' .. entry.ws)
        windower.send_command('gs c set AutoWSMode true')
        windower.add_to_chat(207,
            string.format("[AbysseaProc] Auto-equipping %s / %s (WS: %s)",
                entry.weapon_name, entry.weapon_sub, entry.ws)
        )
        update_display()
    end
end

-------------------------------------------------------------
--  CYCLE WEAPON FOR CURRENT ELEMENT
-------------------------------------------------------------
local function cycle_weapon_for_element()
    if #weapons_for_element == 0 then
        windower.add_to_chat(123,
            string.format("[AbysseaProc] No weapons configured for element: %s", current_element)
        )
        update_display()
        return
    end

    current_weapon_index = current_weapon_index + 1
    if current_weapon_index > #weapons_for_element then
        current_weapon_index = 1
    end

    local entry = weapons_for_element[current_weapon_index]

    windower.send_command('input /equip main "' .. entry.weapon_name .. '";input /equip sub "' .. entry.weapon_sub .. '"')
	windower.add_to_chat(207,
		string.format("[AbysseaProc] [%s] %s / %s - WS: %s",
			current_element, entry.weapon_name, entry.weapon_sub, entry.ws)
	)

    update_display()
end

-------------------------------------------------------------
--  USE WEAPONSKILL FOR CURRENT ELEMENT + WEAPON
-------------------------------------------------------------
local function use_current_ws()
    if current_element == "Kill" then
        windower.send_command('input /ws "' .. kill_ws .. '" <t>')
        windower.add_to_chat(207,
            string.format("[AbysseaProc] Using %s (Kill mode)", kill_ws)
        )
        return
    end

    local entry = weapons_for_element[current_weapon_index]
    if not entry then
        windower.add_to_chat(123,
            "[AbysseaProc] No weapon selected for current element."
        )
        return
    end

    windower.send_command('input /ws "' .. entry.ws .. '" <t>')
	windower.add_to_chat(207,
		string.format("[AbysseaProc] Using %s with %s (%s)",
			entry.ws, entry.weapon_name, current_element)
	)

    update_display()
end

-------------------------------------------------------------
--  COMMAND HANDLER
-------------------------------------------------------------
--  //aproc element  – cycle element
--  //aproc weapon   – cycle weapon for current element
--  //aproc ws       – use weaponskill
--  //aproc reset    – reset element + weapon indices
-------------------------------------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or ''

    if cmd == 'element' then
        cycle_element()
    elseif cmd == 'weapon' then
        cycle_weapon_for_element()
    elseif cmd == 'ws' then
        use_current_ws()
    elseif cmd == 'kill' then
        local args = {...}
        if #args > 0 then
            local full = table.concat(args, ' ')
            local m, s = full:match('^(.+)%s*/%s*(.+)$')
            if m and s then
                kill_weapon = m:trim()
                kill_sub = s:trim()
            else
                kill_weapon = full
            end
            windower.add_to_chat(207, "[AbysseaProc] Kill weapon set to: " .. kill_weapon .. " / " .. kill_sub)
        else
            windower.add_to_chat(207, "[AbysseaProc] Kill weapon: " .. kill_weapon .. " / " .. kill_sub)
        end
    elseif cmd == 'reload' then
        user_settings = dofile(addon_path .. 'data/settings.lua')
        weapon_groups = {}
        for wtype, weapon in pairs(user_settings.weapons) do
            weapon_groups[wtype] = { weapon }
        end
        kill_weapon = user_settings.kill_weapon or "Naegling"
        kill_sub = user_settings.kill_sub or "Blurred Shield +1"
        kill_ws = user_settings.kill_ws or "Savage Blade"
        rebuild_weapons_for_element()
        if #weapons_for_element == 1 then
            current_weapon_index = 1
            local entry = weapons_for_element[current_weapon_index]
            windower.send_command('input /equip main "' .. entry.weapon_name .. '";input /equip sub "' .. entry.weapon_sub .. '"')
        end
        update_display()
        windower.add_to_chat(207, "[AbysseaProc] Settings reloaded.")
    elseif cmd == 'reset' then
        current_element_index = 1
        current_element       = element_order[current_element_index]
        rebuild_weapons_for_element()
        current_weapon_index  = 0
        windower.add_to_chat(207, "[AbysseaProc] Reset to first element and weapon.")
    else
        -- default: treat //aproc as "cycle weapon"
        cycle_weapon_for_element()
    end
end)

-------------------------------------------------------------
--  AUTO-DETECT PROC FROM CHAT
-------------------------------------------------------------

windower.register_event('incoming text', function(original, modified, mode)
    if original:find("attack staggers the fiend!") then
        if kill_enabled then
            windower.send_command('input /equip main "' .. kill_weapon .. '";input /equip sub "' .. kill_sub .. '"')
            -- Re-enable autows for killing
            windower.send_command('gs c autows ' .. kill_ws)
            windower.send_command('gs c set AutoWSMode true')
            windower.add_to_chat(207,
                string.format("[AbysseaProc] Proc landed! Swapping to %s / %s", kill_weapon, kill_sub)
            )
            current_element = "Kill"
            current_element_index = #element_order
            weapons_for_element = {}
            current_weapon_index = 0
            update_display()
        else
            windower.add_to_chat(207, "[AbysseaProc] Proc landed!")
        end
        return
    end

    if not original:find("The fiend appears vulnerable to") then return end
    if not original:find("elemental weapon skills!") then return end

    local element = original:match("The fiend appears vulnerable to (%S+) elemental")
    if not element then return end

    -- Normalize game text to our element names
    if element:lower() == 'darkness' then element = 'Dark' end
    if element:lower() == 'lightning' then element = 'Thunder' end

    -- Find element in our list and set it
    for i, elem in ipairs(element_order) do
        if elem:lower() == element:lower() then
            -- Only auto-equip if element changed
            if current_element == elem then break end
            current_element_index = i
            current_element = element_order[current_element_index]
            rebuild_weapons_for_element()

            -- Auto-equip first weapon for this element
            if #weapons_for_element > 0 then
                current_weapon_index = 1
                local entry = weapons_for_element[current_weapon_index]
                windower.send_command('input /equip main "' .. entry.weapon_name .. '";input /equip sub "' .. entry.weapon_sub .. '"')
                -- Disable autows so we control when to fire proc WS
                windower.send_command('gs c set AutoWSMode false')
                windower.add_to_chat(207,
                    string.format("[AbysseaProc] Auto-detected %s! Equipping %s / %s (WS: %s)",
                        current_element, entry.weapon_name, entry.weapon_sub, entry.ws)
                )
                update_display()

                -- Broadcast to other accounts
                windower.send_ipc_message('aproc_element ' .. current_element)
            end
            break
        end
    end
end)

-------------------------------------------------------------
--  IPC: RECEIVE ELEMENT FROM OTHER ACCOUNTS
-------------------------------------------------------------
windower.register_event('ipc message', function(msg)
    if not msg:find('^aproc_element ') then return end
    local element = msg:match('^aproc_element (.+)$')
    if not element then return end

    for i, elem in ipairs(element_order) do
        if elem:lower() == element:lower() then
            if current_element == elem then break end
            current_element_index = i
            current_element = element_order[current_element_index]
            rebuild_weapons_for_element()

            if #weapons_for_element > 0 then
                current_weapon_index = 1
                local entry = weapons_for_element[current_weapon_index]
                windower.send_command('input /equip main "' .. entry.weapon_name .. '";input /equip sub "' .. entry.weapon_sub .. '"')
                windower.add_to_chat(207,
                    string.format("[AbysseaProc] IPC: %s detected! Equipping %s / %s (WS: %s)",
                        current_element, entry.weapon_name, entry.weapon_sub, entry.ws)
                )
                update_display()
            end
            break
        end
    end
end)

-------------------------------------------------------------
--  LOAD / UNLOAD
-------------------------------------------------------------
windower.register_event('load', function()
    rebuild_weapons_for_element()

    -- Auto-equip if only one weapon for starting element
    if #weapons_for_element == 1 then
        current_weapon_index = 1
        local entry = weapons_for_element[current_weapon_index]
        windower.send_command('input /equip main "' .. entry.weapon_name .. '";input /equip sub "' .. entry.weapon_sub .. '"')
    end

    -- Set autows to starting element's WS
    if #weapons_for_element > 0 then
        local entry = weapons_for_element[1]
        windower.send_command('gs c autows ' .. entry.ws)
        windower.send_command('gs c set AutoWSMode true')
    end

    -- Set Selendrile GearSwap weapons to None so it doesn't fight us
    windower.send_command('gs c weapons None')

    windower.send_command(string.format('bind %s input //aproc element', key_element))
    windower.send_command(string.format('bind %s input //aproc weapon',  key_weapon))
    windower.send_command(string.format('bind %s input //aproc ws',      key_ws))

    windower.add_to_chat(207,
        string.format("[AbysseaProc] Loaded. %s: element, %s: weapon, %s: WS.",
            key_element:upper(), key_weapon:upper(), key_ws:upper())
    )
    windower.add_to_chat(207, "[AbysseaProc] GearSwap weapons set to None.")

    update_display()
end)

windower.register_event('unload', function()
    -- Save HUD position back to settings
    local x, y = info_box:pos()
    local settings_path = addon_path .. 'data/settings.lua'
    local content = io.open(settings_path, 'r'):read('*a')
    content = content:gsub('hud_x%s*=%s*%d+', 'hud_x = ' .. x)
    content = content:gsub('hud_y%s*=%s*%d+', 'hud_y = ' .. y)
    local f = io.open(settings_path, 'w')
    f:write(content)
    f:close()

    windower.send_command(string.format('unbind %s', key_element))
    windower.send_command(string.format('unbind %s', key_weapon))
    windower.send_command(string.format('unbind %s', key_ws))
    if info_box then
        info_box:hide()
    end
end)

--[[
BSD 3-Clause License

Copyright (c) 2026 The Continuum
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of The Continuum nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]


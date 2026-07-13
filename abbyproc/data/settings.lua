-- AbysseaProc Settings
-- Edit your proc weapons and kill weapon here.

return {
    -- Kill weapon (swap back to after proc lands)
    -- Set to false to disable kill mode (proc-only account)
    kill_weapon = "Naegling",
    kill_sub = "Blurred Shield +1",
    kill_ws = "Savage Blade",

    -- Per-character kill overrides (optional)
    -- Character names not listed here use the defaults above
    -- Set kill_weapon to false to disable kill mode for that character
    kill_per_character = {
        -- Deemo = {kill_weapon = "Chango", kill_sub = "Utu Grip", kill_ws = "Upheaval"},
        -- Kiakoda = {kill_weapon = false},  -- proc only, no kill mode
    },

    -- Keybinds
    key_element = 'f10',  -- cycle element
    key_weapon  = 'f11',  -- cycle weapon for current element
    key_ws      = 'f12',  -- use weaponskill

    -- HUD position
    hud_x = 800,
    hud_y = 400,

    -- Proc weapons by type
    -- Each entry: {main = "Weapon Name", sub = "Sub Weapon"}
    weapons = {
        ["Dagger"]       = {main = "Bronze Dagger", sub = "Blurred Shield +1"},
        ["Sword"]        = {main = "Wax Sword", sub = "Blurred Shield +1"},
        ["Great Sword"]  = {main = "Goujian", sub = "Utu Grip"},
        ["Scythe"]       = {main = "Bronze zaghnal", sub = "Utu Grip"},
        ["Polearm"]      = {main = "Tzee Xicu's Blade", sub = "Utu Grip"},
        ["Katana"]       = {main = "Debahocho +1", sub = "Blurred Shield +1"},
        ["Great Katana"] = {main = "Ark Tachi", sub = "Utu Grip"},
        ["Club"]         = {main = "Korrigan mallet", sub = "Blurred Shield +1"},
        ["Staff"]        = {main = "Hapy staff", sub = "Utu Grip"},
    },

    -- Per-character weapon overrides (optional)
    -- Characters not listed use the defaults above
    weapons_per_character = {
        -- Pferi = {
        --     ["Sword"] = {main = "Twinned Blade", sub = "Ammurapi Shield"},
        --     ["Club"]  = {main = "Chac-chacs", sub = "Ammurapi Shield"},
        -- },
    },
}

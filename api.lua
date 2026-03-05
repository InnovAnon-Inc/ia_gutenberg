-- ia_gutenberg/api.lua
-- Core API for document registration and interaction.

local modname = minetest.get_current_modname()
local log     = ia_util.get_logger(modname)
local assert  = ia_util.get_assert(modname)

ia_gutenberg.registered_documents = {}

-- Helper: Check if a document's primary text field is empty
function ia_gutenberg.is_book_blank(itemstack)
    return itemstack:get_meta():get_string("text") == ""
end

local function ensure_privs_exist(priv_table)
    if not priv_table then return end
    for priv, _ in pairs(priv_table) do
        if not minetest.registered_privileges[priv] then
            log(ia_util.log_levels.INFO, "Auto-registering document privilege: " .. priv)
            minetest.register_privilege(priv, {
                description = "Access to restricted documents: " .. priv,
                give_to_singleplayer = false,
            })
        end
    end
end

function ia_gutenberg.register_document(doc_modname, name, def)
    assert(name ~= nil, "Document name is required")
    assert(def.get_text ~= nil, "Document must have a get_text function")

    ensure_privs_exist(def.privs)
    ensure_privs_exist(def.craft_privs)

    local item_name = doc_modname .. ":" .. name
    local base_tex = def.base_image or "default_book.png"
    local final_tex = ia_gutenberg.get_overlay_tex(base_tex, def)

    minetest.register_craftitem(item_name, {
        description = def.description or "A bound document",
        inventory_image = final_tex,
        groups = def.groups or {book = 1, paper = 1, ia_document = 1},
        stack_max = 1,

        on_use = function(itemstack, user, pointed_thing)
            local pname = user:get_player_name()

            if def.privs and not minetest.check_player_privs(pname, def.privs) then
                minetest.chat_send_player(pname, "Security Clearance Denied: Insufficient Privileges.")
                return itemstack
            end

            -- HOOK: Custom on_use logic
            if def.on_use then
                local res = def.on_use(itemstack, user, pointed_thing)
                if res then return res end
            end

            -- STANDARD READER LOGIC
            local target_data = ia_gutenberg.get_target_info(user, pointed_thing)
            local meta = itemstack:get_meta()
            local content = ""

            if def.dynamic or meta:get_string("text") == "" then
                content = def.get_text(itemstack, user, target_data)
                if not def.dynamic then
                    meta:set_string("text", content)
                end
            else
                content = meta:get_string("text")
            end

            local title = def.title or "Document"
            local formspec = "size[8,9]" ..
                "label[0.5,0.5;" .. minetest.formspec_escape(title) .. "]" ..
                "textarea[0.5,1;7.5,7.5;content;;" .. minetest.formspec_escape(content) .. "]" ..
                "button_exit[3,8.2;2,0.8;close;Close]"

            minetest.show_formspec(pname, "ia_gutenberg:reader", formspec)

            if def.on_read then
                def.on_read(itemstack, user, target_data)
            end

            return itemstack
        end
    })

    if def.recipe then
        minetest.register_on_craft(function(itemstack, player, old_grid, inv)
            if itemstack:get_name() == item_name then
                local pname = player:get_player_name()
                if def.craft_privs and not minetest.check_player_privs(pname, def.craft_privs) then
                    log(ia_util.log_levels.WARN, pname .. " attempted to craft restricted document: " .. item_name)
                    minetest.chat_send_player(pname, "You lack the industrial clearance to draft this document.")
                    return ItemStack("") 
                end
            end
        end)

        minetest.register_craft({
            output = item_name,
            type = def.recipe_type or "shapeless",
            recipe = def.recipe,
        })
    end

    ia_gutenberg.registered_documents[item_name] = def
    log(ia_util.log_levels.DEBUG, "Registered document: " .. item_name)
end

-- Field Handler: Processes data sent back from the Gutenberg Reader
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ia_gutenberg:reader" then return end
    if not fields.close and not fields.key_enter then return end

    local itemstack = player:get_wielded_item()
    local item_name = itemstack:get_name()
    local def = ia_gutenberg.registered_documents[item_name]

    if not (def and fields.content) then return end

    -- Determine writability: can be a boolean or a function(itemstack, player)
    local can_write = false
    if type(def.writable) == "function" then
        can_write = def.writable(itemstack, player)
    else
        can_write = def.writable -- works for true/false/nil
    end

    if can_write then
        local meta = itemstack:get_meta()
        if meta:get_string("text") ~= fields.content then
            meta:set_string("text", fields.content)
            player:set_wielded_item(itemstack)
            log(ia_util.log_levels.DEBUG, "Updated text for writable document: " .. item_name)
        end
    end
end)

-- ia_gutenberg/recipes.lua
local modname = minetest.get_current_modname()

ia_gutenberg.recipe_tiers = {
	BASIC = "basic",   -- Just a book and ink
	POWERED = "powered" -- Requires Mese for advanced/command logic
}

-- Returns a shapeless recipe based on tier and additional ingredients
-- @param tier: ia_gutenberg.recipe_tiers (BASIC or POWERED)
-- @param ingredients: Table of additional item strings (e.g. {"default:stick"})
function ia_gutenberg.get_standard_recipe(tier, ingredients)
	-- Start with the mandatory "Ink and Paper"
	local recipe = {"default:book", "dye:black"}
	
	-- Add Mese for powered/advanced books
	if tier == ia_gutenberg.recipe_tiers.POWERED then
		table.insert(recipe, "default:mese_crystal")
	end

	-- Add the unique identifiers (paramaterized items)
	if ingredients then
		for _, item in ipairs(ingredients) do
			table.insert(recipe, item)
		end
	end

	return recipe
end

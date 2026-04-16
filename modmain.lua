-- ============================================
-- Ingredient Insight - Main Module
-- Displays recipe icons when hovering inventory items
-- ============================================

local _G = GLOBAL
local require = _G.require

local RecipeBoard = require("widgets/recipeboard")

local RecipeCache = {}
local HasBuiltCache = false
local HOVER_TRANSFER_GRACE = 0.18

local function IsWidgetOrDescendant(widget, root)
    while widget do
        if widget == root then
            return true
        end
        widget = widget.parent
    end
    return false
end

Assets = {
    Asset("ATLAS", "images/inventoryimages.xml"),
}

local function GetDisplayName(prefab)
    if not prefab or type(prefab) ~= "string" then
        return ""
    end

    local upper_name = string.upper(prefab)
    if _G.STRINGS and _G.STRINGS.NAMES and _G.STRINGS.NAMES[upper_name] then
        return _G.STRINGS.NAMES[upper_name]
    end

    return prefab
end

local function BuildRecipeCache()
    if HasBuiltCache then return end
    if not _G.AllRecipes or type(_G.AllRecipes) ~= "table" then return end
    
    for recipe_name, recipe_data in pairs(_G.AllRecipes) do
        if type(recipe_data) == "table" then
            local ingredients = recipe_data.ingredients
            if type(ingredients) == "table" then
                for _, ingredient_data in ipairs(ingredients) do
                    if type(ingredient_data) == "table" and type(ingredient_data.type) == "string" then
                        local ingredient_type = ingredient_data.type
                        local product_prefab = recipe_data.product or recipe_name
                        
                        if type(product_prefab) == "string" then
                            if not RecipeCache[ingredient_type] then
                                RecipeCache[ingredient_type] = {}
                            end
                            
                            local image_tex = recipe_data.image or (product_prefab .. ".tex")
                            
                            -- ==================================================
                            -- FIX LỖI LỦNG LỖ: Lấy đúng Atlas động của Klei Engine
                            -- ==================================================
                            local atlas = recipe_data.atlas
                            if not atlas and _G.GetInventoryItemAtlas then
                                atlas = _G.GetInventoryItemAtlas(image_tex)
                            end
                            -- Fallback phòng hờ
                            if not atlas then
                                atlas = "images/inventoryimages.xml"
                            end
                            
                            if atlas and image_tex then
                                local already_cached = false
                                for _, cached_recipe in ipairs(RecipeCache[ingredient_type]) do
                                    if cached_recipe.prefab == product_prefab then
                                        already_cached = true
                                        break
                                    end
                                end
                                
                                if not already_cached then
                                    table.insert(RecipeCache[ingredient_type], {
                                        prefab = product_prefab,
                                        display_name = GetDisplayName(product_prefab),
                                        atlas = atlas,
                                        image = image_tex
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    HasBuiltCache = true
end

local function GetRecipesForIngredient(ingredient_type)
    if not ingredient_type or type(ingredient_type) ~= "string" then return nil end
    BuildRecipeCache()
    return RecipeCache[ingredient_type] or nil
end

-- ============================================
-- DIRECT ITEMTILE HOVER LIFECYCLE
-- ============================================
AddClassPostConstruct("widgets/itemtile", function(self)
    
    local old_OnGainFocus = self.OnGainFocus
    local old_OnLoseFocus = self.OnLoseFocus
    local old_OnUpdate = self.OnUpdate

    local function IsHoveringItemOrBoard(tile)
        if not _G.TheInput then
            return false
        end

        local hud_entity = _G.TheInput:GetHUDEntityUnderMouse()
        if not (hud_entity and hud_entity.widget) then
            return false
        end

        if IsWidgetOrDescendant(hud_entity.widget, tile) then
            return true
        end

        if tile.recipe_board and IsWidgetOrDescendant(hud_entity.widget, tile.recipe_board) then
            return true
        end

        return false
    end

    local function EnsureRecipeBoard(tile)
        if not tile.recipe_board then
            tile.recipe_board = tile:AddChild(RecipeBoard(tile))
        end
        return tile.recipe_board
    end

    local function HideRecipeBoard(tile, clear)
        if tile.recipe_board then
            tile.recipe_board:Hide()
            if clear then
                tile.recipe_board:Clear()
            end
        end
    end

    self.OnGainFocus = function(self)
        if old_OnGainFocus then old_OnGainFocus(self) end

        self._ingredient_insight_last_prefab = nil
        self._ingredient_insight_linger = nil
        self:StartUpdating()

        if self.item and self.item.prefab then
            local recipes = GetRecipesForIngredient(self.item.prefab)
            
            if recipes and #recipes > 0 then
                local board = EnsureRecipeBoard(self)
                board:SetRecipes(recipes)
                board:Show()
                board:MoveToFront()
                self._ingredient_insight_last_prefab = self.item.prefab
            else
                HideRecipeBoard(self, false)
            end
        else
            HideRecipeBoard(self, false)
        end
    end

    self.OnLoseFocus = function(self)
        if old_OnLoseFocus then old_OnLoseFocus(self) end

        self._ingredient_insight_last_prefab = nil

        if not IsHoveringItemOrBoard(self) then
            -- Keep the board alive briefly so cursor can travel from item -> board.
            self._ingredient_insight_linger = HOVER_TRANSFER_GRACE
            self:StartUpdating()
            return
        end

        self:StartUpdating()
    end

    self.OnUpdate = function(self, dt)
        if old_OnUpdate then
            old_OnUpdate(self, dt)
        end

        if not IsHoveringItemOrBoard(self) then
            self._ingredient_insight_linger = (self._ingredient_insight_linger or HOVER_TRANSFER_GRACE) - (dt or 0)
            if self._ingredient_insight_linger <= 0 then
                HideRecipeBoard(self, true)
                self:StopUpdating()
            end
            return
        end

        self._ingredient_insight_linger = nil

        if not (self.item and self.item.prefab) then
            return
        end

        local recipes = GetRecipesForIngredient(self.item.prefab)
        if not recipes or #recipes == 0 then
            HideRecipeBoard(self, true)
            self:StopUpdating()
            return
        end

        local board = EnsureRecipeBoard(self)
        if self._ingredient_insight_last_prefab ~= self.item.prefab then
            board:SetRecipes(recipes)
            self._ingredient_insight_last_prefab = self.item.prefab
        end

        board:Show()
        board:MoveToFront()
    end
end)

AddGamePostInit(function()
    BuildRecipeCache()
end)
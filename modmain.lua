local _G = GLOBAL
local require = _G.require

-- ==========================================
-- 1. LOCAL CACHE (REVERSE INDEXING)
-- ==========================================
local ReverseIndex = {}
local CacheText = {}

-- Hàm chạy 1 lần để scan DB gốc của game
local function BuildReverseIndex()
    -- Lặp qua toàn bộ AllRecipes của game
    for recipe_name, recipe_data in pairs(_G.AllRecipes) do
        -- Chỉ lấy các công thức craft được (bỏ qua mấy cái tào lao của dev)
        if recipe_data and recipe_data.ingredients then
            for _, ingredient in ipairs(recipe_data.ingredients) do
                local ing_type = ingredient.type
                
                -- Khởi tạo mảng nếu chưa có
                if not ReverseIndex[ing_type] then
                    ReverseIndex[ing_type] = {}
                end
                
                -- Thêm recipe vào danh sách của ingredient này
                table.insert(ReverseIndex[ing_type], recipe_name)
            end
        end
    end

    -- Format sẵn text để tối ưu Memory Garbage
    for ing_type, recipes in pairs(ReverseIndex) do
        -- UX Logic: Chỉ hiện tối đa 3 items đầu, phần còn lại gom vào (+N)
        local display_count = math.min(3, #recipes)
        local text = "\n🛠️ Craft: "
        
        for i = 1, display_count do
            -- Transform text cho đẹp (ví dụ: rope -> Rope)
            text = text .. recipes[i] .. (i < display_count and ", " or "")
        end
        
        if #recipes > 3 then
            text = text .. " (+" .. tostring(#recipes - 3) .. ")"
        end
        
        CacheText[ing_type] = text
    end
end

-- Gọi hàm build cache ngay khi mod load
BuildReverseIndex()

-- ==========================================
-- 2. CONTEXT VALIDATOR & UI HOOK
-- ==========================================
local ItemTile = require("widgets/itemtile")

-- Hook vào class Hoverer của game
AddClassPostConstruct("widgets/hoverer", function(self)
    -- Giữ lại hàm gốc để gọi sau khi mình chèn logic
    local OldSetString = self.text.SetString
    
    self.text.SetString = function(text_widget, str)
        -- a. Lấy Entity dưới con trỏ chuột
        local hovered_entity = _G.TheInput:GetHUDEntityUnderMouse()
        
        -- b. Context Validator: Chỉ chạy nếu đang hover vào 1 ô đồ (ItemTile)
        if hovered_entity and hovered_entity.widget and hovered_entity.widget:IsA(ItemTile) then
            -- Lấy tên prefab (ID) của cục item đang được hover
            local item_prefab = hovered_entity.widget.item and hovered_entity.widget.item.prefab
            
            -- c. Lấy Text từ Cache (O(1))
            if item_prefab and CacheText[item_prefab] then
                str = str .. CacheText[item_prefab]
            end
        end
        
        -- Gọi lại hàm gốc với chuỗi str đã được modify
        OldSetString(text_widget, str)
    end
end)
# Ingredient Insight

A Don't Starve Together mod that displays available recipes when hovering over inventory items.

## Overview

**Ingredient Insight** enhances the crafting experience in Don't Starve Together by showing all recipes that can be crafted from a hovered inventory item. This mod helps players quickly identify what they can create without needing to search through the crafting menu.

## Features

- **Smart Recipe Display**: Hover over an inventory item to see all available recipes
- **Interactive Recipe Grid**: View up to 8 recipes per page (4×2 grid layout) with large 60×60 pixel icons
- **Easy Navigation**: Use **Left/Right** navigation buttons to browse multiple pages
- **Item Name Display**: Hover over recipe icons to display the item's name with large, readable text (40pt)
- **Smooth Transitions**: Grace timer prevents the dashboard from flickering when moving cursor between item and board
- **Click Deduplication**: Smart input routing prevents accidental double-pagination from simultaneous input handlers

## Installation

1. Download the mod to your Don't Starve Together mods folder:
   ```
   ~/.klei/DoNotStarveTogether/.../mods/Ingredient-Insight/
   ```
   Or on Steam Workshop, subscribe to the mod.

2. Enable the mod in your world's mod settings

3. Start a new game

## Usage

### Viewing Recipes
1. Hover over any item in your inventory
2. The recipe board will appear showing all recipes that use this item as an ingredient

### Navigating Pages
- Click **Left Arrow** button to view previous recipes
- Click **Right Arrow** button to view next recipes
- Page indicator shows current position (e.g., "Page 1/3")

### Viewing Item Names
- Hover over any recipe icon (the small craft item icons) to display its name in large text

## Technical Specifications

**UI Layout**:
- Grid: 4 columns × 2 rows = 8 recipes per page
- Icon Size: 60×60 pixels
- Hover Text Size: 40pt (item names)
- Page Counter: 24pt
- Button Scale: 0.62 for visual consistency

**Key Input Handling**:
- Hover-driven display based on inventory item focus
- Primary click only used by the recipe board's own pagination buttons

**Performance**:
- Caches recipes on startup (one-time operation)
- Efficient widget tree ancestry checking for hover detection
- 0.18s grace timer window for smooth cursor transitions
- Memory cleanup via widget destruction (Clear() on board updates)

## Configuration

Currently, the mod uses default settings. To customize, edit values in:

- `scripts/widgets/recipeboard.lua`:
  - `ICON_SIZE`: Recipe icon dimensions in pixels
  - `GRID_COLS`: Number of columns in recipe grid
  - `MAX_ROWS`: Number of rows in recipe grid
  - `HOVER_TRANSFER_GRACE`: Grace timer duration in seconds (modmain.lua)

## Troubleshooting

### Board not appearing on hover
- Verify the mod is enabled in mod settings
- Check the server logs for LUA errors
- Ensure you're hovering directly over an inventory item

### Page buttons not responding
- Try clicking slightly to the left or right of the button
- Check that the recipe list has multiple pages

### Double page turns on single click
- This should not occur in the current implementation; if it does, verify the board buttons are not being bound twice

## Architecture

### Core Components

**modmain.lua** (Main Module)
- Recipe cache building from `AllRecipes` table
- Hover handling on inventory item tiles
- Board lifecycle management (show/hide based on hover state)

**scripts/widgets/recipeboard.lua** (UI Widget)
- Recipe grid rendering (4×2 layout with pagination)
- Navigation button management (prev/next arrows)
- Hover text display for recipe items
- Page indicator display

### Input Routing Architecture

1. **Itemtile Focus Layer**: Handles hover when cursor is directly over inventory item
   - Visibility trigger point for recipe board

2. **Recipe Board Layer**: Owns pagination and hover name display
   - Prev/next buttons handle page changes locally
   - Hover over recipe icons to show the selected item name

3. **Hover Transfer Grace**: short delay between item and board
   - Keeps the board alive while moving the cursor from item to board
   - Prevents flicker during hover transitions

## Requirements

- **Game**: Don't Starve Together (DST)
- **API Version**: 10
- **Type**: Client-only mod (all clients don't need to have it installed)

## Compatibility

- ✅ Don't Starve Together (DST)
- ❌ Don't Starve (classic)
- ❌ Reign of Giants
- ❌ Shipwrecked

## Version History

### v1.0.0 (Current)
- Initial release with full recipe viewing functionality
- Fixed hover detection for nested widgets
- Implemented grace timer for smooth transitions
- Ensured strict-mode compatibility with local variables

## Author

**Tran Anh Kiet**

## License

This mod is provided as-is for use in Don't Starve Together. Modify for personal use.

## Contributing

To report bugs or suggest improvements, please document:
1. DST version and mod configuration
2. Steps to reproduce the issue
3. Expected vs actual behavior
4. Game log output (if applicable)

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review server logs for error messages
3. Verify mod is compatible with your DST version (API version 10)

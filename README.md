# PeaversSafeList

[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/peavers/PeaversSafeList)](https://github.com/peavers/PeaversSafeList/commits/master) [![Last commit](https://img.shields.io/github/last-commit/peavers/PeaversSafeList)](https://github.com/peavers/PeaversSafeList/master) [![CurseForge](https://img.shields.io/curseforge/dt/1184821?label=CurseForge&color=F16436)](https://www.curseforge.com/wow/addons/peaverssafelist)

**A World of Warcraft addon that creates a snapshot of your entire inventory and allows you to sell everything that's
not in that snapshot with a single command.**

## Overview

PeaversSafeList simplifies inventory management when farming dungeons or other content. When you use the '/psafe save'
command, the addon takes a complete snapshot of every item currently in your bags, creating a "safe list" of those exact
items. Later, when you're at a vendor, the '/psafe sell' command will automatically sell any items in your bags that
weren't part of that original snapshot, letting you quickly unload all newly acquired junk items while protecting your
valuable gear and resources.

## Features

- **Complete Inventory Snapshot**: With a single command, create a snapshot of every item currently in your bags as a
  protected "safe list"
- **Automated Vendor Selling**: Quickly sell any new items not part of your original snapshot with a simple command
- **Persistent Item Memory**: Your safe list persists between game sessions for consistent inventory management
- **Gold Tracking**: Displays earned gold from auto-selling junk items
- **Dungeon-Farmer Friendly**: Ideal for players who frequently farm dungeons and need to manage inventory efficiently
- **Simple Interface**: Minimalist design with straightforward slash commands

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaverssafelist) or use the CurseForge app
2. Extract to your `World of Warcraft/Interface/AddOns` folder
3. Ensure the addon is enabled on the character selection screen

## Usage

1. Organize your inventory with all items you want to keep, then type `/psafe save` to create a complete snapshot of
   your current bags
2. While farming, any new items you collect will not be part of this snapshot
3. When at a vendor, type `/psafe sell` to automatically sell everything that wasn't in your original snapshot
3. Use `/psafe show` to view how many items are in your safe list
4. Use `/psafe clear` to clear your safe list if needed
5. Use `/psafe debug` to toggle debug mode for troubleshooting

## Configuration

- No additional configuration is required as the addon operates through simple slash commands
- The safe list is maintained automatically between gaming sessions

## Support & Feedback

If you encounter any issues or have suggestions for improvements, please submit them
via [GitHub Issues](https://github.com/peavers/PeaversSafeList/issues). Your feedback is valuable in enhancing the addon
experience for all players.

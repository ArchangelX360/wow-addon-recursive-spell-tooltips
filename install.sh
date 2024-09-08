#!/bin/sh -e

addon_name="RecursiveSpellTooltip"
addon_dir="/Applications/World of Warcraft/_retail_/Interface/AddOns/$addon_name"
echo "$(date) 🚀 Installing '$addon_name' add-on..."
rm -r "$addon_dir"
mkdir -p "$addon_dir"
cp -r src/ "$addon_dir"
echo "$(date) ✅ Add-on '$addon_name' installed in '$addon_dir'."
ls -lA --color "$addon_dir"
echo "$(date) Don't forget to '/reload' in game!"

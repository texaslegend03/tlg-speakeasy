# tlg-speakeasy

A lightweight RedM script that introduces immersive speakeasy mechanics, including moonshine delivery, brewing, interior teleportation, and animated NPC interactions. Designed for roleplay servers seeking a touch of Prohibition-era flair.

---

## Features

- Ownable speakeasies with interior access  
- Moonshine delivery system with animated drop-off NPCs  
- Storefront NPCs with ambient animations  
- Routing bucket support for seamless instancing  
- Built-in brewing mini-game

---

## Dependencies

This script relies on the following resources defined in `fxmanifest.lua`:

- `vorp_core`  
- `vorp_inventory`  
- `oxmysql`  
- `vorp_menu`

> ⚠️ **Important:** Do **not** run `moonshine_interiors` alongside this script. It will conflict with interior handling and routing buckets.

---

## Installation

1. **Download or clone this repository** into your RedM resources folder:  
   ```bash
   git clone https://github.com/yourusername/tlg-speakeasy.git
   ```

2. **Add the resource to your server configuration** (`server.cfg` or `resources.cfg`):  
   ```plaintext
   ensure tlg-speakeasy
   ```

3. **Verify that all dependencies** listed above are installed and loaded *before* this resource.

4. **Start your server** and enjoy the speakeasy experience!

---

## Notes

- Interior IDs and routing buckets are managed dynamically.  
- NPC animations are handled client-side for immersion.  
- Future updates may include expanded delivery routes, custom interiors, and voice lines.

---

## License

This project is released under the MIT License. Feel free to fork, modify, and contribute!

---

## Credits

Created by **TexasLegendGaming**  
Special thanks to the RedM community and [femga/rdr3_discoveries](https://github.com/femga/rdr3_discoveries)

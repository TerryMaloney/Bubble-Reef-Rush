# Parallax Background Drop-In

Drop PNGs here named `z<zone>_bg_l<layer>.png` and they appear automatically
in-game, scrolling at depth-based speeds. No code changes needed.

Layers (per zone), back → front:
| File              | Layer            | Scroll speed |
|-------------------|------------------|--------------|
| z1_bg_l5.png      | Light rays / sky | 0.05 (far)   |
| z1_bg_l4.png      | Far background   | 0.15         |
| z1_bg_l3.png      | Mid background   | 0.30         |
| z1_bg_l2.png      | Near background  | 0.60         |
| z1_bg_l1.png      | Foreground       | 1.00         |
| z1_bg_l0.png      | Seabed / ground  | 1.20 (near)  |

- Each PNG is scaled to screen height (1920) and tiled horizontally, so any
  width works (seamless horizontal tiling recommended).
- Only the layers you provide are used; missing layers are skipped.
- If a zone has NO art at all, the flat colour gradient is shown instead.
- Keep the centre band low-contrast so obstacles/pearls stay readable.

Repeat for each zone: z2_bg_l*.png, z3_bg_l*.png, … z6_bg_l*.png.

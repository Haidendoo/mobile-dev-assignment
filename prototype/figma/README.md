# Create the Figma prototype

The local package contains original editable vector/text designs and prototype reactions. It has not been run inside Figma yet; no Figma file or share URL is claimed. Requires Figma Design with access to development plugins (normally the desktop app). No Figma token, network call, external asset, or backend is used by the importer.

## Import

1. Rebuild the package with `python3 scripts/build.py`.
2. Open or create the team's Figma Design file. Use **Plugins → Development → New plugin** and create a **Figma Design / Run once** plugin in a local directory. Figma assigns the plugin's real ID; do not invent or reuse another plugin's ID.
3. Copy this package's generated `code.js` into that plugin directory. Merge the fields in `manifest.template.json` into Figma's generated `manifest.json`, **preserving the real generated `id`**. The template's placeholder ID is intentionally not a runnable manifest. Remove any generated `ui` entry because this importer has no plugin UI.
4. Ensure `main` is `code.js`, `api` is `1.0.0`, `editorType` is `["figma"]`, `documentAccess` is `dynamic-page`, and `networkAccess.allowedDomains` is `["none"]`.
5. Run the development plugin in the target file. It creates a new page, English editable text/shapes, and frame-navigation hotspots. It does not overwrite existing pages. Inter Regular and Bold must be available; failures are reported rather than silently omitting text.
6. Select **SCR-01 / Home**, add a prototype flow starting point in Figma's Prototype panel, and click Present. Review the main route: Play → Level 1 → Right → Right → Completion. Try Undo, Pause, Restart/Cancel, Home/Continue, instructions, rankings, and sound.
7. Select individual error/offline/other-level frames to review their variants. The local preview's Review State selector is an inspection tool and is not added to the product UI. The loading frame has a scripted 1.2-second transition to example scores.
8. Check fonts, labels, clipping, target sizes, contrast, and reactions in Figma. The importer is generated against the documented API but still needs this runtime review. Map previews beyond Level 1 are static design frames.
9. Share the prototype with viewer access, test that URL without editor privileges, and put it in `prototype/links.json` under `figma_url`.
10. Rebuild the document to include the real URL, then update research/approval status only after those tasks actually occur.

## Notes

- `code.js` is generated; change `scripts/artwork.py` / `scripts/build.py` and rebuild rather than editing generated output.
- Imported elements remain editable; frames are 1280 × 720 at 2× for a 640 × 360 dp baseline.
- Re-running imports a separate new page; remove only pages you deliberately no longer need.
- This is scripted A01 navigation, not production Flutter gameplay, persistent preferences, automatic saves, or real online requests. Fixture states are selected for design review.
- SVGs in `prototype/screens/` can also be dragged into Figma for visual reference, but this alone does not create prototype links or native editable text. Prefer the importer.

Primary API references: [manifest](https://developers.figma.com/docs/plugins/manifest/) and [prototype reactions](https://developers.figma.com/docs/plugins/api/properties/nodes-reactions/).

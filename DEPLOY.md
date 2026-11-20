# 천장 청소반 — GitHub Pages deployment

- Repository: `https://github.com/boss489/ceiling-sweep-20261120` (public, `main`).
- Play: `https://boss489.github.io/ceiling-sweep-20261120/`.
- Pages source: `main` `/docs` (GitHub Pages does not accept `/web` as a branch source). `docs/` is a byte-for-byte copy of the Godot 4.7.2 Web release runtime from local `web/`, plus `.nojekyll`. `web/` is intentionally ignored in Git to avoid duplicating ~41 MB of binaries; clone and run `mkdir -p web && godot --headless --editor --path . --quit && godot --headless --path . --export-release Web web/index.html` to regenerate it. Copy the runtime and `web/OFL.txt` into `docs/` before a future Pages update.
- `docs/OFL.txt` is served separately for font attribution; source font and original license live under `assets/`. Art/audio provenance is in `ART.md`.
- Verification: inspect `TESTS.md` for prepublication local checks. A successful push is not enough: compare `git rev-parse HEAD` to `gh api repos/boss489/ceiling-sweep-20261120/commits/main --jq .sha`, ensure Pages latest build is `built` at that commit, compare live HTML/JS/WASM/PCK and OFL SHA-256 to `docs/`, and play the public URL in a browser. Physical-device Safari/Firefox, multitouch, and full player-driven victory are not claimed.
- Rollback: switch Pages source off (or to a known-good commit) via GitHub repository Pages settings; for this initial publication, disable Pages if the new live build fails. Preserve the public source repository unless the owner explicitly authorizes removal.

## Initial publication evidence (2026-11-20)

- Initial release commit `0212aeefc035f3670a00520f03f129a724f50d44` matched the GitHub `main` tip; the Pages build reported `built` for that commit and Actions deployment `success`.
- Fresh HTTPS GET responses were byte-identical to `docs/` for HTML, JS, WASM, PCK, OFL, both audio worklets, and three PNG shell assets. SHA-256: HTML `41f7fa5f72e5ac0745afd1626b4f94391da106f1297223e981e7c51e0d091003`; PCK `d54adfd952f8f44d0ae759f01f600b3887f21ee2c0b582f5579bb590e8c8aa40`.
- Public URL opened the Godot game in Chromium at desktop 1280×577 and mobile-emulated 320×568. Clicked title → tutorial → play and flipped gravity with Space on desktop and the touch-sized button on mobile; screenshots `screenshots/live-{desktop,mobile}-*.png` are local evidence, deliberately excluded from Git. QA query parameters only function on localhost, so these public interactions were not seeded.
- Automated live browser checks do not establish real phone touch/multitouch, Safari/Firefox, audio, or player-driven nine-dust victory; the final local build's result/retry and timed run checks are in `TESTS.md`.

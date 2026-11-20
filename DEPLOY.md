# 천장 청소반 — GitHub Pages deployment

- Repository: `https://github.com/boss489/ceiling-sweep-20261120` (public, `main`).
- Play: `https://boss489.github.io/ceiling-sweep-20261120/`.
- Pages source: `main` `/docs` (GitHub Pages does not accept `/web` as a branch source). `docs/` is a byte-for-byte copy of the Godot 4.7.2 Web release runtime from local `web/`, plus `.nojekyll`. `web/` is intentionally ignored in Git to avoid duplicating ~41 MB of binaries; clone and run `mkdir -p web && godot --headless --editor --path . --quit && godot --headless --path . --export-release Web web/index.html` to regenerate it. Copy the runtime and `web/OFL.txt` into `docs/` before a future Pages update.
- `docs/OFL.txt` is served separately for font attribution; source font and original license live under `assets/`. Art/audio provenance is in `ART.md`.
- Verification: inspect `TESTS.md` for prepublication local checks. A successful push is not enough: compare `git rev-parse HEAD` to `gh api repos/boss489/ceiling-sweep-20261120/commits/main --jq .sha`, ensure Pages latest build is `built` at that commit, compare live HTML/JS/WASM/PCK and OFL SHA-256 to `docs/`, and play the public URL in a browser. Physical-device Safari/Firefox, multitouch, and full player-driven victory are not claimed.
- Rollback: switch Pages source off (or to a known-good commit) via GitHub repository Pages settings; for this initial publication, disable Pages if the new live build fails. Preserve the public source repository unless the owner explicitly authorizes removal.

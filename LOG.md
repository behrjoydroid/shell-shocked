# LOG

- 2026-11-02: M0 item 1, partly done: `git init` on `main`, three docs committed (af13d77). GitHub remote still open, so the box stays unchecked: no repo exists yet and `gh` isn't installed.
  Git HTTPS fails on this PC (Norton intercepts TLS, Git's OpenSSL bundle doesn't trust it); `git -c http.sslBackend=schannel ...` works and still verifies certificates.
- 2026-11-02: M0 item 1 finished: `origin` is github.com/behrjoydroid/shell-shocked, GitHub's initial README merged in, `main` pushed. This repo has `http.sslBackend=schannel` set for the Norton problem above.
- 2026-11-02: M0 items 2 and 3 done together, at Joey's request: Godot project, circle that walks with WASD or arrows, `tests/run.gd` with an empty test. Tests check with `assert()`, and any error logged during a test fails it; that needs `OS.add_logger`, so the minimum Godot is now 4.5.
- 2026-11-02: M1 item 1 done: move and aim separately (WASD or arrows and mouse, or both sticks), sprint with Shift or stick click, stamina bar on a new HUD. Tuning is in `data/soldier.json`. Stamina runs out, then sprint locks until it recovers to `stamina_recover_at`.
- 2026-11-02: M1 item 2 done: rifle with magazine, fire rate and reload (`data/weapons.json`), bullets that travel and hit, ammo count on the HUD. Added three bare dummies so hits can be seen; they only flash and count, so the dummy and sound item is still open. Spare ammo is unlimited until M4.

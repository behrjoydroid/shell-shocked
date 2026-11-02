# LOG

- 2026-11-02: M0 item 1, partly done: `git init` on `main`, three docs committed (af13d77). GitHub remote still open, so the box stays unchecked: no repo exists yet and `gh` isn't installed.
  Git HTTPS fails on this PC (Norton intercepts TLS, Git's OpenSSL bundle doesn't trust it); `git -c http.sslBackend=schannel ...` works and still verifies certificates.
- 2026-11-02: M0 item 1 finished: `origin` is github.com/behrjoydroid/shell-shocked, GitHub's initial README merged in, `main` pushed. This repo has `http.sslBackend=schannel` set for the Norton problem above.
- 2026-11-02: M0 items 2 and 3 done together, at Joey's request: Godot project, circle that walks with WASD or arrows, `tests/run.gd` with an empty test. Tests check with `assert()`, and any error logged during a test fails it; that needs `OS.add_logger`, so the minimum Godot is now 4.5.

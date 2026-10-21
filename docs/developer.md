# Development loop

Setup facts (`SITE_URL`, `PHP_ERROR_LOG`, `DB_BACKUP_DIR`, versions, paths): `.env.local`, rewritten each session by `.claude/hooks/laragon-env.ps1`; never edit it.

## 1. Run

- WP-CLI: PowerShell, project root. Git Bash turns `/…` arguments into `C:/Program Files/Git/…`: keep it for text tools and `curl`.
- PowerShell 5.1 strips `"` inside arguments: `wp eval "echo get_option('blogname');"`, or `wp eval-file` a scratchpad file.
- `wp db query` turns `%` into spaces: `Get-Content <file>.sql -Raw | wp db query`.
- "Error establishing a database connection": MySQL is down. Ask the user to **Start All** in Laragon; never start services yourself.

## 2. Change

- WP-CLI over raw SQL or wp-admin.
- Before changing data (import, `search-replace`, bulk delete, reset): `wp db export` to `DB_BACKUP_DIR`, and say where.

## 3. Check

- `php -l` the changed files, `curl.exe -sk` the page for 200, read the newest lines of `PHP_ERROR_LOG`.
- WordPress notices: set `WP_DEBUG` and `WP_DEBUG_LOG` true and `WP_DEBUG_DISPLAY` false (`wp config set <NAME> <value> --raw`), read `wp-content/debug.log`, then set all three back.

## 4. Report

- What changed, and what to look at in the browser.

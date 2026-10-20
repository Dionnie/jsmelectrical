# JSM Electrical: WordPress website

WordPress, run locally with Laragon. A `[gap: …]` marker is a missing fact or an open decision: fill it in when the user gives it, never guess.

**Setup facts come from the SessionStart report** (`.claude/hooks/laragon-env.ps1`), not this file: versions, paths, site address, logs, backup folder, the "Load Laragon's PATH" line, WordPress state. Trust it, and never copy from it into here. If it's missing or Laragon has changed, re-run `.\.claude\hooks\laragon-env.ps1 -Text`.

## Rules

1. **Never edit core or code you don't own:** `wp-admin/`, `wp-includes/`, root `wp-*.php`, bundled themes, third-party plugins. Site code goes in [gap: a child theme of Twenty Twenty-Five, or a custom theme: not chosen yet]; small site-wide code in `wp-content/mu-plugins/`.
2. **WP-CLI first** for settings, content, users, plugins and the database, over raw SQL or wp-admin clicks.
3. **Ask before adding a plugin:** say what it does, and the lighter option (a few lines of site code) if there is one.
4. **Back up the database before changing data** (import, `search-replace`, bulk delete, reset): `wp db export` to the report's backup folder (create it if missing), and say where. Git doesn't hold the database or uploads.
5. **The Site Editor saves to the database:** `wp_template`, `wp_template_part`, `wp_global_styles` and `wp_navigation` posts override theme files. If a theme file change doesn't show, list them: `wp post list --post_type=wp_template,wp_template_part,wp_global_styles,wp_navigation --post_status=any --fields=ID,post_type,post_name,post_modified`.
6. **Check every change** (below), then report what changed and what to look at in the browser.

## Running commands

Claude's shells get the system PATH, not Laragon's, and its PHP can differ from the site's.

- **Start every PowerShell command that runs `php`, `wp`, `mysql`, `composer` or `git` with the report's "Load Laragon's PATH" line** (shell state doesn't carry over): `<loader line>; wp …`.
- **Run WP-CLI from PowerShell, from the project root** (no `--url` needed). Git Bash rewrites `/…` arguments into `C:/Program Files/Git/…`: use it only for text tools and `curl`.
- PowerShell 5.1 strips `"` inside arguments: write `wp eval "echo get_option('blogname');"`, or put longer PHP in a scratchpad file and `wp eval-file` it.
- `wp db query` turns `%` into spaces, so `LIKE '%…%'` matches nothing: write the SQL to a scratchpad file and `Get-Content <file>.sql -Raw | wp db query`. Other commands keep `%`.
- In PowerShell, `curl` is `Invoke-WebRequest`: use `curl.exe`.
- "Error establishing a database connection" means MySQL is down: ask the user to **Start All** in Laragon; don't start services yourself.
- `wp-config.php`: never print or copy its keys and salts (`wp config get <NAME>`, never `wp config list`). Change constants with `wp config set … --raw`, not by hand.
- A command for the user: one line, cmd syntax, run from the project root in their VS Code (Laragon) terminal, with no PATH prefix.

## Checking a change

- **PHP:** `php -l <file>`, with Laragon's PATH loaded.
- **Page:** `curl.exe -sk -o NUL -w "%{http_code}" <site address><path>/`.
- **Errors:** the report's logs; PHP's is shared by every Laragon site and WP-CLI, so read its newest lines. For WordPress notices: set `WP_DEBUG` and `WP_DEBUG_LOG` true and `WP_DEBUG_DISPLAY` false, read `wp-content/debug.log`, tell the user, and set them back after.
- **Email:** everything PHP sends lands in Mailpit (inbox in the report).
- **Before a deploy:** `wp core verify-checksums; wp plugin verify-checksums --all`.

## Git

The repo is the project root, pushed to https://github.com/Dionnie/jsmelectrical (`main`).

- `.gitignore` is an allow-list. Tracked: `wp-content/themes/`, `plugins/` and `mu-plugins/` (except what WordPress ships: Twenty Twenty-* themes, Akismet, Hello Dolly; `*-child` themes are tracked), `README.md`, `CLAUDE.md`, `.claude/` (not `settings.local.json`). Core, `wp-config.php`, `.htaccess`, uploads, `*.sql` and logs stay out.
- A new folder at the root or in `wp-content` is ignored until added to `.gitignore`; `git check-ignore -v <path>` says which rule.
- Read `git status` before every commit: never commit `wp-config.php` or a database export.

## Live site and deploying

[gap: live address, host, the server's PHP version, how files and the database get there]. Never upload `CLAUDE.md`, `.claude/` or database exports (a deploy from Git copies only `wp-content`). After moving the database: `wp search-replace '<local address>' '<live address>' --dry-run` first, then for real; then `wp option update blog_public 1`.

# JSM Electrical: WordPress website

The JSM Electrical website: WordPress, run locally with Laragon. Every `[gap: …]` marker is a missing fact or an open decision: fill it in when the user gives it, never guess.

**The live setup comes from the session-start report, not from this file.** At the start of every session, the SessionStart hook in `.claude/settings.json` runs `.claude/hooks/laragon-env.ps1`, which detects the Laragon setup and adds it to Claude's context: services and their versions, the PHP Apache runs, the site address, the logs, the backup folder, the line that loads Laragon's PATH, WordPress's state, and warnings when something doesn't match. Trust it over anything written here. If it's missing, or the user has changed Laragon since (switched PHP, restarted services), run `.\.claude\hooks\laragon-env.ps1 -Text` in PowerShell. Never copy versions or paths from it into this file.

## How to work here

1. **Never edit WordPress core or code you don't own:** `wp-admin/`, `wp-includes/`, the root `wp-*.php` files, the bundled themes and third-party plugins. Updates overwrite them. This site's code goes in [gap: a child theme of Twenty Twenty-Five, or a custom theme: not chosen yet]; small site-wide code goes in a plugin in `wp-content/mu-plugins/`.
2. **Use WP-CLI first** for settings, content, users, plugins and the database: prefer it to raw SQL and to asking the user to click through wp-admin.
3. **Ask before adding a plugin.** Each one is a dependency to update and secure. Say what it does, and the lighter option (a few lines of site code) if there is one.
4. **Back up the database before changing data.** Git (below) keeps the site's code, not the database or uploads. Export to the report's backup folder (below) before an import, a `search-replace`, a bulk delete or a reset, and say where the export is.
5. **Remember the Site Editor writes to the database.** Changes made in Appearance → Editor are saved as `wp_template`, `wp_template_part`, `wp_global_styles` and `wp_navigation` posts, and they override the theme's files. The report counts them; if a theme file change doesn't show, list them: `wp post list --post_type=wp_template,wp_template_part,wp_global_styles,wp_navigation --post_status=any --fields=ID,post_type,post_name,post_modified`.
6. **Check every change** (below). Then report what changed, and what the user should look at in the browser.

## Running commands

The user's VS Code terminal is Laragon's: its default profile ("Laragon") runs Cmder's `init.bat`, which calls Laragon's `laragon.cmd`, and that puts every Laragon tool on PATH, with the PHP Laragon has selected. Claude's shells don't run it: the extension starts its own Windows PowerShell 5.1 (`-NoProfile`) and Git Bash, which get only the system PATH, and that PATH's PHP can differ from the site's (the report warns when it does). So:

- **Start every PowerShell command that runs `php`, `wp`, `mysql` or `composer` with the report's "Load Laragon's PATH" line.** Then `php -l` and WP-CLI run the PHP Apache runs, and the MySQL client and Composer are there. Shell state doesn't carry between commands, so repeat it each time: `<loader line>; wp db query "SELECT VERSION();"`.
- **Run WP-CLI from PowerShell, never Git Bash.** Git Bash rewrites any argument that starts with `/` into a Windows path: `wp.bat rewrite structure '/%postname%/'` would save `C:/Program Files/Git/%postname%/`, and `/wp-content/uploads` becomes `C:/Program Files/Git/wp-content/uploads`. Use Git Bash only for text tools and `curl`.
- Run WP-CLI from the project root. It skips the dynamic URL block in `wp-config.php` and uses the database's `siteurl` and `home`, so `--url` isn't needed.
- PowerShell 5.1 strips double quotes inside an argument: `wp eval 'echo get_option("blogname");'` fails. Use single quotes inside (`wp eval "echo get_option('blogname');"`), escape them as `\"`, or write longer PHP to a scratchpad file and run `wp eval-file <file>`.
- `wp db query` turns every `%` in the SQL into a space (it hands the SQL to `mysql` through PHP's `escapeshellarg()`, which does that on Windows), so `LIKE '%…%'` silently matches nothing. Write the SQL to a scratchpad file and pipe it in: `Get-Content <file>.sql -Raw | wp db query`. Arguments to other commands keep their `%` (`wp rewrite structure '/%postname%/'` is fine).
- In PowerShell, `curl` is an alias for `Invoke-WebRequest`: use `curl.exe`.
- "Error establishing a database connection" means MySQL isn't running (the report says which service is down). Ask the user to **Start All** in Laragon; don't start services yourself.
- A command for the user to run is one line in cmd syntax, for their VS Code terminal or Cmder, run from the project root. Every Laragon tool is on PATH there, so it needs no prefix.

## WP-CLI quick reference

Laragon's PATH loaded first, as above.

```powershell
wp option get blogname                               # read a setting; wp option update to change it
wp post list --post_type=page --fields=ID,post_title,post_status
wp plugin list; wp theme list                        # what's installed and active
wp plugin install <slug> --activate                  # only after the user agrees (rule 3)
wp config set WP_DEBUG true --raw                    # change a wp-config constant
wp config get DB_NAME                                # read one constant; never wp config list (prints the salts)
wp rewrite flush; wp cache flush; wp transient delete --all

# Database: export to the report's backup folder, which is outside the web root.
$b = '<backup folder>'; New-Item -ItemType Directory -Force $b | Out-Null
wp db export "$b\$(Get-Date -Format yyyy-MM-dd_HHmm).sql"
wp search-replace '<local address>' '<live address>' --dry-run --report-changed-only   # always dry-run first
```

## Checking a change

- **PHP edited:** `php -l <file>`, with Laragon's PATH loaded, so it checks against the site's PHP.
- **Page loads:** `curl.exe -sk -o NUL -w "%{http_code}" <site address><path>/` (`-k` because Laragon's certificate is self-signed).
- **Errors:** the logs the report lists. PHP's log is shared by every Laragon site and by WP-CLI: read its newest lines. For WordPress notices, set `WP_DEBUG` and `WP_DEBUG_LOG` to true and `WP_DEBUG_DISPLAY` to false (`wp config set … --raw`), read `wp-content/debug.log`, say you did, and set them back when done.
- **Email:** everything PHP sends, to any address, lands in Mailpit, at the inbox the report gives.
- **Core untouched:** `wp core verify-checksums` and `wp plugin verify-checksums --all`, before any deploy.

## Local notes

- **`wp-config.php`:** never print or copy its keys and salts. Change constants with `wp config set`, not by hand. It builds the site URL from each request, so http and https both load locally; the database holds the real address.
- **Database tools:** phpMyAdmin at http://localhost/phpmyadmin/, or HeidiSQL from Laragon's **Database** button.

## Git

The repository is the project root, pushed to https://github.com/Dionnie/jsmelectrical (branch `main`). Use Laragon's Git, the one the user's terminal runs: load Laragon's PATH first, as for `wp`.

- **`.gitignore` is an allow-list.** It tracks `wp-content/themes/`, `wp-content/plugins/` and `wp-content/mu-plugins/`, third-party ones included, except those that ship with WordPress (the Twenty Twenty-* themes, Akismet, Hello Dolly); a `*-child` theme is tracked. It also tracks `README.md`, `CLAUDE.md` and `.claude/` (not `.claude/settings.local.json`). Everything else stays out: core, `wp-config.php`, `.htaccess`, uploads, `*.sql`, logs.
- A new folder at the root, or in `wp-content` beside those three, is ignored until it's added to `.gitignore`. `git check-ignore -v <path>` says which rule ignores a path.
- Read `git status` before every commit: never commit `wp-config.php` or a database export.

## Live site and deploying

[gap: live address, host, the server's PHP version, how files and the database get there]. Whatever the method: never upload `CLAUDE.md`, `.claude/` or database exports (the first two are in Git, so a deploy that pulls from Git must copy only `wp-content`); after moving the database, run `wp search-replace` from the local address to the live one (dry run first); and turn search engines back on (`wp option update blog_public 1`).

---
Last Updated: 2026-10-20 · Senior Web Developer (AI-assisted) · New: entry point for the WordPress site, written from the Laragon install as found (WP-CLI from Claude's shells, the MySQL PATH and PowerShell quoting workarounds, logs, Mailpit, database backups without Git).
Last Updated: 2026-10-20 · Senior Web Developer (AI-assisted) · Running commands: found the user's VS Code terminal runs Laragon's Cmder init; Claude's shells now load Laragon's PATH from `laragon.cmd` instead of a hard-coded MySQL folder (covers Composer too, and follows Laragon's version switches).
Last Updated: 2026-10-20 · Senior Web Developer (AI-assisted) · Re-tested every command: WP-CLI from PowerShell only (Git Bash rewrites `/…` arguments); `wp db query` drops `%` (pipe SQL from a file); Apache's log is `error_log`, not `error.log`; MySQL's log added.
Last Updated: 2026-10-20 · Senior Web Developer (AI-assisted) · No more hard-coded setup (owner): versions, paths, addresses, service state and WordPress state now come from the SessionStart report (`.claude/hooks/laragon-env.ps1`); the PATH line is now for every php/wp command, since Laragon's PHP and Claude's plain PHP can differ.
Last Updated: 2026-10-20 · Senior Web Developer (AI-assisted) · Git added (owner): new Git section; `.gitignore` tracks wp-content themes, plugins and mu-plugins (not the ones WordPress ships) and the project docs, not core, `wp-config.php`, uploads or the database; rule 4 no longer says there is no Git.

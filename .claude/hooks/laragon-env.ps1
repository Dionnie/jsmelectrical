<#
  Session-start check for Claude Code. Detects the live Laragon setup for this project (services,
  versions, the PHP Apache really runs, the site address, logs, WordPress state) and writes it to
  .env.local. Claude gets only a summary, the warnings, and Laragon's PATH line while Claude's own
  PATH needs it, so CLAUDE.md never has to name a version or a path.
  Wired up in .claude/settings.json (SessionStart). By hand: .\.claude\hooks\laragon-env.ps1 -Text
  Reads only, apart from .env.local: it changes nothing in Laragon, WordPress or the database.
#>
param([switch]$Text)
$ErrorActionPreference = 'SilentlyContinue'

$project = $env:CLAUDE_PROJECT_DIR
if (-not $project) { $project = (Get-Location).Path }
$project = (Resolve-Path $project).Path.TrimEnd('\')
$name = Split-Path $project -Leaf

# Laragon's root is the nearest parent folder holding laragon.exe. Anywhere else, say nothing.
$root = $project
while ($root -and -not (Test-Path (Join-Path $root 'laragon.exe'))) { $root = Split-Path $root -Parent }
if (-not $root) { exit 0 }

# Runs a program with a time limit. Returns its exit code and output, or $null.
function Run([string]$exe, [string[]]$argv, [int]$ms = 15000) {
    if (-not $exe -or -not (Test-Path $exe)) { return $null }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = ($argv | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $project
    $p = [Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync()
    $err = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($ms)) { try { $p.Kill() } catch {}; return $null }
    [pscustomobject]@{ Code = $p.ExitCode; Out = $out.Result.Trim(); Err = $err.Result.Trim() }
}
function Same([string]$a, [string]$b) { $a -and $b -and ($a.TrimEnd('\') -eq $b.TrimEnd('\')) }
function Leaf([string]$p) { if ($p) { Split-Path $p -Leaf } }

$warn = New-Object System.Collections.Generic.List[string]
$plainPhp = (Get-Command php.exe -CommandType Application | Select-Object -First 1).Source
$plainWp = (Get-Command wp -CommandType Application | Select-Object -First 1).Source

# Laragon's terminal PATH: the same laragon.cmd that Cmder and the VS Code "Laragon" profile run.
$loader = Join-Path $root 'bin\laragon\laragon.cmd'
$lpath = @()
if (Test-Path $loader) {
    $m = [regex]::Match((Get-Content $loader -Raw), 'SET "PATH=([^"]*)"')
    if ($m.Success) { $lpath = @($m.Groups[1].Value -split ';' | Where-Object { $_ -and $_ -notmatch '%' }) }
} else {
    $warn.Add("$loader is missing, so Laragon's PATH can't be loaded.")
}
$under = @($lpath | Where-Object { $_ -like "$root\*" })
foreach ($d in @($under | Where-Object { -not (Test-Path $_) })) { $warn.Add("Laragon's PATH lists $d, which doesn't exist.") }
function LDir([string]$like) { $under | Where-Object { $_ -like "$root\bin\$like" } | Select-Object -First 1 }
$phpCliDir = LDir 'php\*'
$mysqlBin = LDir 'mysql\*'
$apacheBin = LDir 'apache\*'
$wpcli = $lpath | ForEach-Object { Join-Path $_ 'wp-cli.phar' } | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($lpath) { $env:PATH = ($lpath -join ';') + ';' + $env:PATH }

# What is running, and on which ports.
$procs = @(Get-CimInstance Win32_Process -Filter "Name='laragon.exe' OR Name='httpd.exe' OR Name='nginx.exe' OR Name='mysqld.exe' OR Name='mailpit.exe'")
$listen = @(Get-NetTCPConnection -State Listen)
function Proc([string]$n) { $procs | Where-Object { $_.Name -eq $n } | Select-Object -First 1 }
function Ports([string]$n) {
    $ids = @($procs | Where-Object { $_.Name -eq $n } | ForEach-Object { $_.ProcessId })
    @($listen | Where-Object { $ids -contains $_.OwningProcess } | ForEach-Object { $_.LocalPort } | Sort-Object -Unique)
}
$apache = Proc 'httpd.exe'
$nginx = Proc 'nginx.exe'
$mysqld = Proc 'mysqld.exe'
$mailpit = Proc 'mailpit.exe'
if (-not (Proc 'laragon.exe')) { $warn.Add('Laragon is not running.') }
if (-not $apache -and -not $nginx) { $warn.Add('No web server is running: ask the user to Start All in Laragon.') }
if (-not $mysqld) { $warn.Add('MySQL is not running: every WP-CLI command will fail with a database connection error.') }

# The PHP the site really runs: Apache's mod_php line (Laragon writes it), else Laragon's selected PHP.
$sitePhpDir = $null
if (-not $nginx) {
    $m = [regex]::Match((Get-Content (Join-Path $root 'etc\apache2\mod_php.conf') -Raw), 'LoadModule\s+php\w*_module\s+"([^"]+)"')
    if ($m.Success) { $sitePhpDir = Split-Path ($m.Groups[1].Value -replace '/', '\') -Parent }
}
if (-not $sitePhpDir) { $sitePhpDir = $phpCliDir }
function PhpInfo([string]$dir) {
    $r = Run (Join-Path $dir 'php.exe') @('-r', "echo implode('|', array(PHP_VERSION, ini_get('memory_limit'), ini_get('upload_max_filesize'), ini_get('post_max_size'), ini_get('error_log'), ini_get('sendmail_path')));")
    if ($r -and $r.Code -eq 0) {
        $f = ($r.Out -split "`n")[-1] -split '\|'
        [pscustomobject]@{ Dir = $dir; Version = $f[0]; Memory = $f[1]; Upload = $f[2]; Post = $f[3]; ErrorLog = $f[4]; Sendmail = $f[5] }
    }
}
$site = PhpInfo $sitePhpDir
if (-not $site) { $warn.Add("Can't run the site's PHP in $sitePhpDir.") }
$cliVer = $null
if ($phpCliDir -and -not (Same $phpCliDir $sitePhpDir)) {
    $cliVer = (PhpInfo $phpCliDir).Version
    $warn.Add("Laragon's PATH has PHP $cliVer ($phpCliDir), but the site runs $($site.Version): reload Laragon or re-select PHP in its menu.")
}
$plainVer = $null
if ($plainPhp -and -not (Same (Split-Path $plainPhp -Parent) $sitePhpDir)) {
    $r = Run $plainPhp @('-r', 'echo PHP_VERSION;')
    if ($r) { $plainVer = $r.Out }
    $warn.Add("Claude's plain PATH runs PHP $plainVer, not the site's $($site.Version): load Laragon's PATH before php or wp, or WP-CLI and php -l test against the wrong PHP.")
}
# Claude needs Laragon's PATH line until its own PATH has the site's PHP and WP-CLI.
$needLoader = -not ($plainPhp -and (Same (Split-Path $plainPhp -Parent) $sitePhpDir) -and $plainWp)

# Versions of the other services.
$apacheVer = $null
if ($apacheBin) { $apacheVer = [regex]::Match((Run (Join-Path $apacheBin 'httpd.exe') @('-v')).Out, 'Apache/(\S+)').Groups[1].Value }
$mysqlVer = $null
if ($mysqlBin) { $mysqlVer = [regex]::Match((Run (Join-Path $mysqlBin 'mysql.exe') @('--version')).Out, 'Ver (\S+)').Groups[1].Value }
$mysqlLog = $null
if ($mysqld) { $mysqlLog = [regex]::Match($mysqld.CommandLine, '--log-error=("[^"]+"|\S+)').Groups[1].Value.Trim('"') }
$mailpitExe = $null
if ($site) { $mailpitExe = [regex]::Match($site.Sendmail, '([A-Za-z]:[^"]*?mailpit\.exe)').Groups[1].Value }
$mailpitVer = Leaf (Split-Path $mailpitExe -Parent)
$mailPorts = Ports 'mailpit.exe'
if ($site -and -not $mailpitExe) { $warn.Add("PHP's sendmail_path is not Mailpit ($($site.Sendmail)): local email may really be sent.") }
elseif (-not $mailpit) { $warn.Add('Mailpit is not running: emails the site sends are lost.') }

# The site's address, from Laragon's virtual host for this folder.
$projFwd = [regex]::Escape(($project -replace '\\', '/'))
$host_ = $null; $https = $false; $vhost = $null
if ($nginx) {
    $vhost = Get-ChildItem (Join-Path $root 'etc\nginx\sites-enabled') -Filter *.conf | Where-Object { (Get-Content $_.FullName -Raw) -match ('root\s+"?' + $projFwd) } | Select-Object -First 1
    if ($vhost) { $c = Get-Content $vhost.FullName -Raw; $host_ = [regex]::Match($c, 'server_name\s+([^\s;]+)').Groups[1].Value; $https = $c -match 'listen\s+443' }
} else {
    $vhost = Get-ChildItem (Join-Path $root 'etc\apache2\sites-enabled') -Filter *.conf | Where-Object { (Get-Content $_.FullName -Raw) -match ('define ROOT "' + $projFwd + '"') } | Select-Object -First 1
    if ($vhost) { $c = Get-Content $vhost.FullName -Raw; $host_ = [regex]::Match($c, 'define SITE "([^"]+)"').Groups[1].Value; $https = $c -match ':443' }
}
if (-not $host_) { $host_ = "$name.test"; $warn.Add("No Laragon virtual host found for $project; guessed $host_.") }
$scheme = 'http'
if ($https) { $scheme = 'https' }
$url = "${scheme}://$host_/"
$code = (Run "$env:SystemRoot\System32\curl.exe" @('-sk', '-o', 'NUL', '-w', '%{http_code}', '--max-time', '8', $url) 12000).Out
if ($code -notmatch '^[23]') { $warn.Add("$url answered HTTP $code.") }

$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$inbox = $null
if ($mailpit) { $inbox = "http://localhost:$($mailPorts | Where-Object { $_ -ne 1025 } | Select-Object -First 1)/" }
$apacheLog = $null
if ($apacheBin -and -not $nginx) { $apacheLog = Join-Path (Split-Path $apacheBin -Parent) 'logs\error_log' }
$backup = Join-Path $root "backup\$name"

# WordPress, read through WP-CLI on the site's own PHP (plugins and theme code not loaded).
$versionFile = Join-Path $project 'wp-includes\version.php'
if (Test-Path $versionFile) {
    $vf = Get-Content $versionFile -Raw
    $wpVer = [regex]::Match($vf, "\`$wp_version = '([^']+)'").Groups[1].Value
    $reqPhp = [regex]::Match($vf, "\`$required_php_version = '([^']+)'").Groups[1].Value
    try { if ($site -and [version]($site.Version -replace '[^\d.].*$') -lt [version]$reqPhp) { $warn.Add("WordPress $wpVer needs PHP $reqPhp+, but the site runs $($site.Version).") } } catch {}
    $wp = $null
    if ($mysqld -and $wpcli -and $site) {
        $probe = Join-Path $env:TEMP "laragon-env-probe-$PID.php"
        Set-Content -Path $probe -Encoding ascii -Value @'
<?php
global $wpdb;
if ( ! function_exists( 'get_plugin_data' ) ) { require_once ABSPATH . 'wp-admin/includes/plugin.php'; }
$t = wp_get_theme();
$parent = $t->parent();
$plugins = array();
foreach ( (array) get_option( 'active_plugins' ) as $f ) {
    $d = get_plugin_data( WP_PLUGIN_DIR . '/' . $f, false, false );
    $slug = dirname( $f );
    $plugins[] = array(
        'slug'  => '.' === $slug ? basename( $f, '.php' ) : $slug,
        'label' => trim( ( $d['Name'] ? $d['Name'] : $f ) . ' ' . $d['Version'] ),
    );
}
$tz = get_option( 'timezone_string' );
echo json_encode( array(
    'siteurl'    => get_option( 'siteurl' ),
    'home'       => get_option( 'home' ),
    'env'        => wp_get_environment_type(),
    'db'         => array( 'name' => DB_NAME, 'user' => DB_USER, 'password' => '' !== DB_PASSWORD, 'host' => DB_HOST, 'prefix' => $wpdb->prefix ),
    'theme'      => array( 'name' => $t->get( 'Name' ), 'version' => $t->get( 'Version' ), 'slug' => get_stylesheet() ),
    'parent'     => $parent ? array( 'name' => $parent->get( 'Name' ), 'version' => $parent->get( 'Version' ), 'slug' => get_template() ) : null,
    'block'      => method_exists( $t, 'is_block_theme' ) && $t->is_block_theme(),
    'plugins'    => $plugins,
    'mu'         => array_keys( get_mu_plugins() ),
    'editor'     => $wpdb->get_results( "SELECT post_type, COUNT(*) AS n FROM {$wpdb->posts} WHERE post_type IN ('wp_template','wp_template_part','wp_global_styles','wp_navigation') GROUP BY post_type", ARRAY_A ),
    'permalinks' => get_option( 'permalink_structure' ),
    'timezone'   => $tz ? $tz : 'UTC' . sprintf( '%+g', get_option( 'gmt_offset' ) ),
    'public'     => (int) get_option( 'blog_public' ),
    'debug'      => array( WP_DEBUG, defined( 'WP_DEBUG_LOG' ) && WP_DEBUG_LOG, ! defined( 'WP_DEBUG_DISPLAY' ) || WP_DEBUG_DISPLAY ),
) );
'@
        $r = Run (Join-Path $sitePhpDir 'php.exe') @($wpcli, 'eval-file', $probe, "--path=$project", '--skip-plugins', '--skip-themes') 25000
        Remove-Item $probe -Force
        if ($r -and $r.Code -eq 0) { $wp = ($r.Out -split "`n")[-1] | ConvertFrom-Json }
        else { $why = 'timed out'; if ($r) { $why = (($r.Err + "`n" + $r.Out).Trim() -split "`n")[0] }; $warn.Add("WP-CLI couldn't read WordPress: $why") }
    }
    if ($wp) {
        $perm = 'plain'; if ($wp.permalinks) { $perm = $wp.permalinks }
        $seo = 'discouraged'; if ($wp.public) { $seo = 'allowed' }
    }
}

# .env.local is rewritten only when this script made it, so a developer's own file is never lost.
$envFile = Join-Path $project '.env.local'
$mine = '.claude/hooks/laragon-env.ps1'
$ours = -not (Test-Path $envFile) -or ((Get-Content $envFile -TotalCount 1) -like "*$mine*")
if (-not $ours) { $warn.Add(".env.local wasn't written by $mine, so it was left as it is.") }

# The same facts for developers, as .env.local: KEY=value lines that dotenv tools can load too.
# No key is a variable that PHP, MySQL, Git, WordPress or WP-CLI read from the environment.
$E = New-Object System.Collections.Generic.List[string]
function Key([string]$k, $v) {
    if ($v -is [bool]) { $v = "$v".ToLower() } elseif ($v -is [array]) { $v = $v -join ',' }
    $v = "$v"
    if ($v -notmatch '^[\w.,:/\\@+-]*$') { $q = "'"; if ($v -match "'") { $q = '"' }; $v = "$q$v$q" }
    $E.Add("$k=$v")
}
$E.Add("# Laragon setup for $name, detected $now by $mine.")
$E.Add('# Rewritten at every Claude Code session start, so edits here are lost. Local to this PC; Git ignores it.')
$E.Add('# Refresh by hand, from the project root: powershell -NoProfile -ExecutionPolicy Bypass -File .claude\hooks\laragon-env.ps1 -Text')
$E.Add('# Values with spaces or symbols are single-quoted, so dotenv tools read them literally.')
$E.Add(''); $E.Add('# Site')
Key 'SITE_URL' $url
Key 'SITE_HTTP_STATUS' $code
Key 'SITE_DIR' $project
Key 'SITE_VHOST' $vhost.FullName
$E.Add(''); $E.Add("# Laragon. Its terminal PATH comes from LARAGON_CMD; to load it in another PowerShell:")
$E.Add("#   `$env:PATH = (cmd /c 'call $loader && set PATH') -match '^PATH=' -replace '^PATH=', ''")
Key 'LARAGON_ROOT' $root
Key 'LARAGON_RUNNING' ([bool](Proc 'laragon.exe'))
Key 'LARAGON_CMD' $loader
$E.Add(''); $E.Add('# Web server')
if ($nginx) { Key 'WEB_SERVER' 'nginx'; Key 'WEB_SERVER_VERSION' ''; Key 'WEB_SERVER_RUNNING' $true; Key 'WEB_SERVER_PORTS' (Ports 'nginx.exe') }
else { Key 'WEB_SERVER' 'apache'; Key 'WEB_SERVER_VERSION' $apacheVer; Key 'WEB_SERVER_RUNNING' ([bool]$apache); Key 'WEB_SERVER_PORTS' (Ports 'httpd.exe') }
$E.Add(''); $E.Add('# PHP the site runs')
Key 'PHP_VERSION' $site.Version
Key 'PHP_DIR' $sitePhpDir
Key 'PHP_MEMORY_LIMIT' $site.Memory
Key 'PHP_UPLOAD_MAX_FILESIZE' $site.Upload
Key 'PHP_POST_MAX_SIZE' $site.Post
if ($cliVer) { $E.Add("# Laragon's terminal PATH has another PHP: reload Laragon or re-select PHP in its menu"); Key 'PHP_TERMINAL_VERSION' $cliVer; Key 'PHP_TERMINAL_DIR' $phpCliDir }
if ($plainVer) { $E.Add("# Outside Laragon's terminal, the system PATH runs another PHP"); Key 'PHP_SYSTEM_VERSION' $plainVer; Key 'PHP_SYSTEM_BIN' $plainPhp }
$E.Add(''); $E.Add('# MySQL. Database backups (wp db export) go to DB_BACKUP_DIR')
Key 'MYSQL_VERSION' $mysqlVer
Key 'MYSQL_RUNNING' ([bool]$mysqld)
Key 'MYSQL_PORTS' (Ports 'mysqld.exe')
Key 'DB_BACKUP_DIR' $backup
if ($wp) {
    $pw = 'none'; if ($wp.db.password) { $pw = 'set there, not copied here' }
    $E.Add("# The site's database, from wp-config.php. Password: $pw")
    Key 'DB_NAME' $wp.db.name
    Key 'DB_USER' $wp.db.user
    Key 'DB_HOST' $wp.db.host
    Key 'DB_TABLE_PREFIX' $wp.db.prefix
}
if ($mailpitExe) {
    $E.Add(''); $E.Add("# Mailpit: PHP's mail() delivers here, whatever the address")
    Key 'MAILPIT_VERSION' $mailpitVer
    Key 'MAILPIT_RUNNING' ([bool]$mailpit)
    Key 'MAILPIT_URL' $inbox
    Key 'MAILPIT_PORTS' $mailPorts
}
$E.Add(''); $E.Add("# Tools on Laragon's PATH")
Key 'TOOL_WPCLI' $wpcli
Key 'TOOL_MYSQL' $mysqlBin
Key 'TOOL_COMPOSER' (LDir 'composer*')
Key 'TOOL_NODE' (LDir 'nodejs\*')
Key 'TOOL_PYTHON' (LDir 'python\*')
Key 'TOOL_GIT' (LDir 'git\*')
$E.Add(''); $E.Add("# Logs. PHP's is shared by every Laragon site and by WP-CLI")
Key 'PHP_ERROR_LOG' $site.ErrorLog
if ($apacheLog) { Key 'APACHE_ERROR_LOG' $apacheLog }
Key 'MYSQL_ERROR_LOG' $mysqlLog
if (Test-Path $versionFile) {
    $E.Add(''); $E.Add("# WordPress, read through WP-CLI on the site's PHP")
    Key 'WP_VERSION' $wpVer
    Key 'WP_REQUIRES_PHP' $reqPhp
    if ($wp) {
        Key 'WP_SITEURL' $wp.siteurl
        Key 'WP_HOME' $wp.home
        Key 'WP_ENVIRONMENT' $wp.env
        Key 'WP_THEME' $wp.theme.slug
        Key 'WP_THEME_NAME' $wp.theme.name
        Key 'WP_THEME_VERSION' $wp.theme.version
        Key 'WP_BLOCK_THEME' ([bool]$wp.block)
        Key 'WP_PARENT_THEME' $wp.parent.slug
        Key 'WP_PLUGINS' @($wp.plugins | ForEach-Object { $_.slug })
        Key 'WP_MU_PLUGINS' @($wp.mu)
        Key 'WP_PERMALINKS' $perm
        Key 'WP_TIMEZONE' $wp.timezone
        Key 'WP_SEARCH_ENGINES' $seo
        Key 'WP_DEBUG' ([bool]$wp.debug[0])
        Key 'WP_DEBUG_LOG' ([bool]$wp.debug[1])
        Key 'WP_DEBUG_DISPLAY' ([bool]$wp.debug[2])
        $n = @{}; foreach ($x in @($wp.editor)) { $n[$x.post_type] = [int]$x.n }
        $E.Add("# Site Editor posts in the database (they override the theme's files)")
        Key 'WP_EDITOR_TEMPLATES' ([int]$n['wp_template'])
        Key 'WP_EDITOR_TEMPLATE_PARTS' ([int]$n['wp_template_part'])
        Key 'WP_EDITOR_GLOBAL_STYLES' ([int]$n['wp_global_styles'])
        Key 'WP_EDITOR_NAVIGATION' ([int]$n['wp_navigation'])
    } else {
        $E.Add('# The rest is unknown until WP-CLI can reach the database.')
    }
}
if ($warn.Count) { $E.Add(''); $E.Add('# Warnings'); foreach ($w in $warn) { $E.Add("# - $w") } }
if ($ours) { try { [IO.File]::WriteAllText($envFile, ($E -join "`n") + "`n", (New-Object Text.UTF8Encoding $false)) } catch {} }

# What Claude gets every session; the details stay in .env.local, read when needed.
$summary = "Laragon: Apache $apacheVer, PHP $($site.Version), MySQL $mysqlVer, Mailpit $mailpitVer; $url HTTP $code"
if ($nginx) { $summary = $summary -replace '^Laragon: Apache \S*,', 'Laragon: Nginx,' }
$C = New-Object System.Collections.Generic.List[string]
$C.Add("$summary (detected $now). Paths, logs, DB_BACKUP_DIR and WordPress state: .env.local. After a Laragon change, refresh it: .\.claude\hooks\laragon-env.ps1 -Text")
if ($needLoader) { $C.Add("Start every PowerShell command that runs php, wp, mysql, composer or git with Laragon's PATH: `$env:PATH = (cmd /c 'call $loader && set PATH') -match '^PATH=' -replace '^PATH=', ''") }
if ($warn.Count) { $C.Add('Warnings:'); foreach ($w in $warn) { $C.Add("- $w") } }
$context = $C -join "`n"

if ($Text) { $context; exit 0 }
if ($warn.Count) { $summary += "; $($warn.Count) warning(s): $($warn[0])" }
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::Out.Write((@{ systemMessage = $summary; hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $context } } | ConvertTo-Json -Depth 4 -Compress))
exit 0

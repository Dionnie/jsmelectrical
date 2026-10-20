<#
  Session-start report for Claude Code. Detects the live Laragon setup for this project (services,
  versions, the PHP Apache really runs, the site address, logs, WordPress state) and hands it to
  Claude as context, so CLAUDE.md never has to name a version or a path.
  Wired up in .claude/settings.json (SessionStart). By hand: .\.claude\hooks\laragon-env.ps1 -Text
  Reads only: it changes nothing in Laragon, WordPress or the database.
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

# The report.
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$L = New-Object System.Collections.Generic.List[string]
$L.Add("Laragon setup for this project, detected at session start ($now) by .claude/hooks/laragon-env.ps1. Trust it over any version or path written elsewhere. If the user changes Laragon (PHP version, services, sites), re-run it: .\.claude\hooks\laragon-env.ps1 -Text")
$state = 'running'; if (-not (Proc 'laragon.exe')) { $state = 'NOT running' }
$L.Add("- Laragon: $state, root $root")
if ($nginx) { $L.Add("- Web server: Nginx, running (ports $((Ports 'nginx.exe') -join ', '))") }
elseif ($apache) { $L.Add("- Web server: Apache $apacheVer, running (ports $((Ports 'httpd.exe') -join ', '))") }
else { $L.Add("- Web server: Apache $apacheVer, NOT running") }
$L.Add("- Site: $url answers HTTP $code (virtual host: $(Leaf $vhost.FullName))")
if ($site) { $L.Add("- PHP the site runs: $($site.Version) ($($site.Dir)); memory_limit $($site.Memory), upload_max_filesize $($site.Upload), post_max_size $($site.Post)") }
if ($cliVer) { $L.Add("- PHP on Laragon's PATH: $cliVer ($phpCliDir)") } else { $L.Add("- PHP on Laragon's PATH: the same") }
if ($plainVer) { $L.Add("- PHP on Claude's plain PATH: $plainVer ($plainPhp): differs from the site") } else { $L.Add("- PHP on Claude's plain PATH: the same as the site") }
$state = 'NOT running'; if ($mysqld) { $state = "running (port $((Ports 'mysqld.exe') -join ', '))" }
$L.Add("- MySQL: $mysqlVer, $state")
if ($mailpitExe) {
    $state = 'NOT running'
    if ($mailpit) { $ui = $mailPorts | Where-Object { $_ -ne 1025 } | Select-Object -First 1; $state = "running, inbox http://localhost:$ui/ (listening on $($mailPorts -join ', '))" }
    $L.Add("- Mailpit $mailpitVer`: $state. PHP's mail() delivers there, whatever the address")
}
$tools = @()
if ($wpcli) { $tools += "WP-CLI ($wpcli)" }
if (LDir 'composer*') { $tools += 'Composer' }
if (LDir 'nodejs\*') { $tools += "Node $(Leaf (LDir 'nodejs\*'))" }
if (LDir 'python\*') { $tools += "Python $(Leaf (LDir 'python\*'))" }
if (LDir 'git\*') { $tools += "Laragon's Git" }
$L.Add("- On Laragon's PATH: MySQL client, $($tools -join ', ')")
$logs = @()
if ($site.ErrorLog) { $logs += "PHP $($site.ErrorLog) (shared by every Laragon site and by WP-CLI)" }
if ($apacheBin -and -not $nginx) { $logs += "Apache $(Join-Path (Split-Path $apacheBin -Parent) 'logs\error_log')" }
if ($mysqlLog) { $logs += "MySQL $mysqlLog" }
$L.Add("- Logs: $($logs -join '; ')")
$L.Add("- Database backups go to: $(Join-Path $root "backup\$name")\")
$L.Add("- Load Laragon's PATH at the start of every PowerShell command that runs php, wp, mysql or composer:")
$L.Add("  `$env:PATH = (cmd /c 'call $loader && set PATH') -match '^PATH=' -replace '^PATH=', ''")

# WordPress, read through WP-CLI on the site's own PHP (plugins and theme code not loaded).
$versionFile = Join-Path $project 'wp-includes\version.php'
if (Test-Path $versionFile) {
    $vf = Get-Content $versionFile -Raw
    $wpVer = [regex]::Match($vf, "\`$wp_version = '([^']+)'").Groups[1].Value
    $reqPhp = [regex]::Match($vf, "\`$required_php_version = '([^']+)'").Groups[1].Value
    try { if ($site -and [version]($site.Version -replace '[^\d.].*$') -lt [version]$reqPhp) { $warn.Add("WordPress $wpVer needs PHP $reqPhp+, but the site runs $($site.Version).") } } catch {}
    $L.Add("WordPress (read through WP-CLI on the site's PHP):")
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
    $plugins[] = trim( ( $d['Name'] ? $d['Name'] : $f ) . ' ' . $d['Version'] );
}
$tz = get_option( 'timezone_string' );
echo json_encode( array(
    'siteurl'    => get_option( 'siteurl' ),
    'home'       => get_option( 'home' ),
    'env'        => wp_get_environment_type(),
    'db'         => DB_NAME . ' as ' . DB_USER . ( '' === DB_PASSWORD ? ' (no password)' : ' (password set)' ) . ' on ' . DB_HOST . ', table prefix ' . $wpdb->prefix,
    'theme'      => $t->get( 'Name' ) . ' ' . $t->get( 'Version' ) . ' (' . get_stylesheet() . ')',
    'parent'     => $parent ? $parent->get( 'Name' ) . ' ' . $parent->get( 'Version' ) : '',
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
        $onoff = { param($b) if ($b) { 'on' } else { 'off' } }
        $L.Add("- Core $wpVer (needs PHP $reqPhp+); siteurl $($wp.siteurl), home $($wp.home); environment type $($wp.env)")
        $L.Add("- Database: $($wp.db)")
        $kind = 'classic theme'; if ($wp.block) { $kind = 'block theme' }
        $par = 'no parent'; if ($wp.parent) { $par = "child of $($wp.parent)" }
        $L.Add("- Active theme: $($wp.theme), $kind, $par")
        $pl = 'none'; if (@($wp.plugins).Count) { $pl = @($wp.plugins) -join ', ' }
        $mu = 'none'; if (@($wp.mu).Count) { $mu = @($wp.mu) -join ', ' }
        $L.Add("- Active plugins: $pl; must-use plugins: $mu")
        $ed = 'none'; if (@($wp.editor).Count) { $ed = (@($wp.editor) | ForEach-Object { "$($_.post_type) $($_.n)" }) -join ', ' }
        $L.Add("- Site Editor posts in the database (they override the theme's files): $ed")
        $perm = 'plain'; if ($wp.permalinks) { $perm = $wp.permalinks }
        $seo = 'discouraged'; if ($wp.public) { $seo = 'allowed' }
        $L.Add("- Permalinks $perm; timezone $($wp.timezone); search engines $seo; WP_DEBUG $(& $onoff $wp.debug[0]) (log $(& $onoff $wp.debug[1]), display $(& $onoff $wp.debug[2]))")
    } else {
        $L.Add("- Core $wpVer (needs PHP $reqPhp+); the rest is unknown until WP-CLI can reach the database")
    }
}

if ($warn.Count) { $L.Add('Warnings:'); foreach ($w in $warn) { $L.Add("- $w") } }
$report = $L -join "`n"

if ($Text) { $report; exit 0 }
$summary = "Laragon: Apache $apacheVer, PHP $($site.Version), MySQL $mysqlVer, Mailpit $mailpitVer; $url HTTP $code"
if ($nginx) { $summary = $summary -replace '^Laragon: Apache \S*,', 'Laragon: Nginx,' }
if ($warn.Count) { $summary += "; $($warn.Count) warning(s): $($warn[0])" }
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::Out.Write((@{ systemMessage = $summary; hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $report } } | ConvertTo-Json -Depth 4 -Compress))
exit 0

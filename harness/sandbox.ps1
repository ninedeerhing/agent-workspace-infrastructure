Set-StrictMode -Version Latest

<#
.SYNOPSIS
    AWI Sandbox Adapter — executes project tooling with isolated cache paths.
.DESCRIPTION
    In restricted-write environments (IDE sandboxes, containerized workspaces),
    global tool caches may be unwritable. This wrapper fixes cache paths to
    stay within the project directory, avoiding permission errors.

    Currently wraps `uv` for Python projects. Extend for other package managers
    (npm, cargo, etc.) by adding new wrapper functions following the same pattern.

.PARAMETER Tool
    Tool to wrap: "uv" (default).
    All remaining arguments are passed to the tool.

.EXAMPLE
    .\harness\sandbox.ps1 sync --frozen --dev
    .\harness\sandbox.ps1 run python tools/qa_env_check.py
    .\harness\sandbox.ps1 run pytest -q -m "not db and not external"
#>

param(
    [ValidateSet("uv")]
    [string]$Tool = "uv",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ToolArgs
)

function Get-RepoRoot {
    <#
    .SYNOPSIS
        Compute the project repository root.
    #>
    if ($PSScriptRoot) {
        return Split-Path -Parent $PSScriptRoot
    }
    return (Get-Location).Path
}

function Get-SandboxCacheDir {
    <#
    .SYNOPSIS
        Get project-isolated cache directory, ensuring it exists.

    .DESCRIPTION
        Restricted environments may inject an unwritable global cache dir
        (e.g. UV_CACHE_DIR in Trae sandbox). This creates a local `.sandbox_cache`
        inside the project root, avoiding permission errors when the tool tries
        to write `.gitignore`, `CACHEDIR.TAG`, or other metadata files.
    #>
    $repoRoot = Get-RepoRoot
    $cacheDir = Join-Path $repoRoot ".sandbox_cache"
    if (-not (Test-Path -LiteralPath $cacheDir -PathType Container)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    return $cacheDir
}

function Invoke-SandboxUv {
    <#
    .SYNOPSIS
        Execute uv with project-isolated cache directory.

    .DESCRIPTION
        Appends `--cache-dir <repo>/.sandbox_cache` to all uv arguments,
        overriding any sandbox-injected `UV_CACHE_DIR`. The command semantics
        (`sync`, `run`, `lock`, etc.) remain unchanged.
    #>
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$UvArgs
    )

    $cacheDir = Get-SandboxCacheDir
    $allArgs = @("--cache-dir", $cacheDir) + $UvArgs
    & uv @allArgs
    exit $LASTEXITCODE
}

# Main dispatch
switch ($Tool) {
    "uv" { Invoke-SandboxUv @ToolArgs }
}

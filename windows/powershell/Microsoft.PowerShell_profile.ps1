$env:EDITOR = 'hx'
$env:VISUAL = 'hx'
$bunBin = Join-Path $HOME '.bun\bin'
if ((Test-Path -LiteralPath $bunBin) -and $env:PATH -notlike "*$bunBin*") {
    $env:PATH = "$bunBin;$env:PATH"
}

if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise activate pwsh | Out-String | Invoke-Expression
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init powershell | Out-String | Invoke-Expression
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    starship init powershell | Out-String | Invoke-Expression
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function global:ls { eza --long --all --group-directories-first @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
    function global:cat { bat --paging=never @args }
}

Set-Alias -Name lg -Value lazygit -Scope Global -ErrorAction SilentlyContinue

if (Get-Command bun -ErrorAction SilentlyContinue) {
    function global:tsc { bunx --bun tsc @args }
}

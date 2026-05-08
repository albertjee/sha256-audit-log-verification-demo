<#
.SYNOPSIS
    Verifies a SHA-256 hash-chained audit log.

.DESCRIPTION
    This script validates whether a sealed audit log has been modified after sealing.

    It performs three checks:

    1. Recomputes each event hash from the audit event payload.
    2. Verifies each event points to the previous event hash.
    3. Compares the final event hash to a trusted anchor.

    This script is verification-only.
    It does not create, seal, or repair audit logs.

.NOTES
    Demo purpose:
    Tamper-evident audit verification.

    Important:
    Hash chaining does not make an audit log impossible to modify.
    It makes unauthorized modification detectable when validated against
    a trusted anchor.
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $AuditLogPath,

    [Parameter(Mandatory = $true)]
    [string] $AnchorPath
)

function ConvertTo-CanonicalJson {
    param (
        [Parameter(Mandatory = $true)]
        [object] $Event
    )

    # The hash input must match the original sealed payload.
    # EventHash is excluded because it is the output of the hash operation.
    $payload = [ordered]@{
        Action       = $Event.Action
        EventId      = $Event.EventId
        OperatorId   = $Event.OperatorId
        PreviousHash = $Event.PreviousHash
        Result       = $Event.Result
        TargetObject = $Event.TargetObject
        TimestampUtc = $Event.TimestampUtc
    }

    return ($payload | ConvertTo-Json -Depth 10 -Compress)
}

function Get-Sha256Hash {
    param (
        [Parameter(Mandatory = $true)]
        [string] $InputString
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hashBytes = $sha256.ComputeHash($bytes)

    return (($hashBytes | ForEach-Object { $_.ToString("x2") }) -join "")
}

Write-Host ""
Write-Host "AUDIT LOG INTEGRITY CHECK"
Write-Host "-------------------------"

if (-not (Test-Path $AuditLogPath)) {
    Write-Host "Result: FAIL"
    Write-Host "Reason: Audit log file not found."
    Write-Host "Path: $AuditLogPath"
    exit 1
}

if (-not (Test-Path $AnchorPath)) {
    Write-Host "Result: FAIL"
    Write-Host "Reason: Trusted anchor file not found."
    Write-Host "Path: $AnchorPath"
    exit 1
}

try {
    $auditEvents = Get-Content -Path $AuditLogPath -Raw | ConvertFrom-Json
}
catch {
    Write-Host "Result: FAIL"
    Write-Host "Reason: Audit log is not valid JSON."
    exit 1
}

$trustedAnchor = (Get-Content -Path $AnchorPath -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($trustedAnchor)) {
    Write-Host "Result: FAIL"
    Write-Host "Reason: Trusted anchor is empty."
    exit 1
}

$expectedPreviousHash = "GENESIS"
$lastHash = $null
$eventCount = 0

foreach ($event in ($auditEvents | Sort-Object EventId)) {

    $eventCount++

    if ($event.PreviousHash -ne $expectedPreviousHash) {
        Write-Host ""
        Write-Host "Result: FAIL"
        Write-Host ""
        Write-Host "Broken event: $($event.EventId)"
        Write-Host "Reason: PreviousHash does not match the prior event hash."
        Write-Host ""
        Write-Host "Expected PreviousHash:"
        Write-Host $expectedPreviousHash
        Write-Host ""
        Write-Host "Actual PreviousHash:"
        Write-Host $event.PreviousHash
        Write-Host ""
        Write-Host "Conclusion:"
        Write-Host "The audit chain linkage was modified, reordered, or broken."
        exit 1
    }

    $canonicalJson = ConvertTo-CanonicalJson -Event $event
    $recomputedHash = Get-Sha256Hash -InputString $canonicalJson

    if ($recomputedHash -ne $event.EventHash) {
        Write-Host ""
        Write-Host "Result: FAIL"
        Write-Host ""
        Write-Host "Broken event: $($event.EventId)"
        Write-Host "Reason: Stored EventHash does not match recomputed SHA-256 hash."
        Write-Host ""
        Write-Host "Stored EventHash:"
        Write-Host $event.EventHash
        Write-Host ""
        Write-Host "Recomputed EventHash:"
        Write-Host $recomputedHash
        Write-Host ""
        Write-Host "Conclusion:"
        Write-Host "The audit event was modified after sealing."
        exit 1
    }

    $expectedPreviousHash = $event.EventHash
    $lastHash = $event.EventHash
}

if ($lastHash -ne $trustedAnchor) {
    Write-Host ""
    Write-Host "Result: FAIL"
    Write-Host ""
    Write-Host "Reason: Final chain hash does not match trusted anchor."
    Write-Host ""
    Write-Host "Trusted anchor:"
    Write-Host $trustedAnchor
    Write-Host ""
    Write-Host "Current final chain hash:"
    Write-Host $lastHash
    Write-Host ""
    Write-Host "Conclusion:"
    Write-Host "The audit chain may have been rebuilt, replaced, truncated, or altered."
    exit 1
}

Write-Host ""
Write-Host "Result: PASS"
Write-Host ""
Write-Host "Events validated: $eventCount"
Write-Host "Broken event: none"
Write-Host "Final chain hash matches trusted anchor."
Write-Host ""
Write-Host "Conclusion:"
Write-Host "The audit log validates against the trusted hash anchor."
exit 0
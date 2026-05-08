# SHA-256 Hash-Chained Audit Log Verification Demo

**Author:** Albert Jee  
**License:** MIT  
**Copyright:** Copyright (c) 2026 Albert Jee. All rights reserved.

This repository demonstrates how a sealed audit log can be independently verified for post-sealing modification.

The purpose of this demo is simple:

> The audit log can be edited. The evidence chain cannot be silently edited.

This is a verification-only demo. It provides a pre-sealed sample audit log, a trusted final hash anchor, and a PowerShell verifier.

It does not publish the private audit-log sealing engine.

---

![SHA-256 Hash-Chained Audit Sealing](./assets/sha256-hash-chained-audit-sealing.png)

---

## What This Demo Shows

This demo shows how SHA-256 hash chaining can be used to detect whether an audit log was modified after it was sealed.

Each audit event contains:

- Event ID
- UTC timestamp
- Operator identity
- Action
- Target object
- Result
- Previous event hash
- Current event hash

The verifier performs three checks:

1. Recomputes each event hash.
2. Verifies each event points to the previous event hash.
3. Compares the final chain hash to a trusted anchor.

If any event is changed after sealing, validation fails.

---

## What This Demo Does Not Claim

This demo is about tamper evidence, not tamper prevention.

Hash chaining does not make a log impossible to modify. It makes unauthorized modification detectable when the log is validated against a trusted anchor.

This repository is not a production logging system, SIEM replacement, WORM storage design, HSM-backed signing system, or compliance certification artifact.

---

## Repository Contents

```text
sha256-audit-log-verification-demo/
|
|-- README.md
|-- LICENSE
|-- assets/
|   |-- sha256-hash-chained-audit-sealing.png
|-- samples/
|   |-- sealed-audit-log.json
|   |-- trusted-anchor.txt
|
|-- tools/
    |-- Test-AuditLogIntegrity.ps1
```

---

## Quick Start

Clone the repository:

```powershell
git clone https://github.com/albertjee/sha256-audit-log-verification-demo.git
cd sha256-audit-log-verification-demo
```

Run the verifier:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\Test-AuditLogIntegrity.ps1" `
  -AuditLogPath ".\samples\sealed-audit-log.json" `
  -AnchorPath ".\samples\trusted-anchor.txt"
```

Expected result:

```text
AUDIT LOG INTEGRITY CHECK
-------------------------

Result: PASS

Events validated: 5
Broken event: none
Final chain hash matches trusted anchor.

Conclusion:
The audit log validates against the trusted hash anchor.
```

---

## Tamper Test

Open the sample audit log:

```text
samples/sealed-audit-log.json
```

Find Event 2 and change:

```json
"Result":  "Success"
```

to:

```json
"Result":  "Skipped"
```

Save the file.

Run the verifier again:

```powershell
powershell -ExecutionPolicy Bypass -File ".\tools\Test-AuditLogIntegrity.ps1" `
  -AuditLogPath ".\samples\sealed-audit-log.json" `
  -AnchorPath ".\samples\trusted-anchor.txt"
```

Expected result:

```text
Result: FAIL

Broken event: 2
Reason: Stored EventHash does not match recomputed SHA-256 hash.

Conclusion:
The audit event was modified after sealing.
```

---

## Why the Trusted Anchor Matters

A hash chain detects local event modification.

The trusted anchor detects whether the final chain hash still matches the original sealed state.

In this demo, the trusted anchor is stored in:

```text
samples/trusted-anchor.txt
```

In a production system, a trusted anchor would normally be stored outside the audit log's administrative boundary, such as in a SIEM, WORM storage, ticketing system, evidence register, or signing service.

---

## Standards Alignment

This demo is not a certification claim.

The pattern supports common audit-log integrity and evidence-protection objectives found in security frameworks such as:

- NIST SP 800-53
- NIST SP 800-92
- CIS Controls
- ISO/IEC 27001
- SOC 2
- PCI DSS

Specifically, this demo supports:

- audit record integrity
- tamper evidence
- operator traceability
- event-chain validation
- trusted final-hash anchoring

---

## Intellectual Property Boundary

This repository intentionally publishes only the verification side of the pattern.

It does not include:

- the private audit-log sealing engine
- production evidence workflow
- external anchoring implementation
- signing-key management design
- customer or tenant-specific implementation logic

The sample audit log uses fictional data only.

---

## License

The PowerShell verifier and demo code are released under the MIT License.

The architecture graphic, explanatory text, and documentation are copyright (c) 2026 Albert Jee unless otherwise stated.

See [LICENSE](./LICENSE) for details.

---

## Author

Created by **Albert Jee**  
Enterprise Identity Architect | IAM Consultant

Copyright (c) 2026 Albert Jee. All rights reserved.

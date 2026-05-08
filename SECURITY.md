\# Security Policy



\## Purpose



This repository is a demonstration project for verifying a SHA-256 hash-chained audit log.



It is intentionally verification-only.



This repository does not include:



\- the private audit-log sealing engine

\- production evidence workflow

\- external anchoring implementation

\- signing-key management design

\- customer or tenant-specific implementation logic



\## Reporting Security Issues



If you identify a security issue in the verifier or documentation, please open a GitHub issue in this repository.



Do not include sensitive data, secrets, tenant identifiers, customer information, or private logs in any public issue.



\## Demo Limitations



This project demonstrates tamper evidence, not tamper prevention.



Hash chaining does not make an audit log impossible to modify. It makes unauthorized modification detectable when validated against a trusted anchor.



This repository is not a production logging platform, SIEM replacement, WORM storage design, HSM-backed signing system, or compliance certification artifact.



\## Author



Created by Albert Jee  

Enterprise Identity Architect | IAM Consultant



Copyright (c) 2026 Albert Jee. All rights reserved.


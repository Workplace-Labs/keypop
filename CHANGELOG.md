# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Compact list snippet generation (`[prefix]-list`) on kit import to easily browse imported keywords.
- Curated prompt collections `kits/workplace-labs.snippets.json` and `kits/lab-rats.snippets.json`.

## [0.1.0] - 2026-07-01

### Added
- Unified keypop CLI combining text replacement management and background daemon.
- Objective-C runtime bridge to KeyboardServices (KSPrivateBridge) for safe, private API interaction.
- Background daemon (keypop run) supporting keyboard event tap for terminal and editor text expansion.
- Automatic snippet synchronization and atomic backup system under private/backups/.
- Built-in diagnostics with keypop inspect, keypop read-sources, and keypop db-summary.
- GitHub Actions CI workflow with macOS runner.

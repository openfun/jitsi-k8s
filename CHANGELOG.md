# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Terraform project to create a K8S cluster on scaleway
- Kustomize project to deploy jitsi on K8S

### Fixed

- Fix password generation on macos
- Fix `k8s-apply-config` in Makefile for macos users
- Merge `cert-issuer` related files in base and overlays
- Change default octo bridge selection strategy from SplitBridge to SingleBridge
- Overlays template initializes all domain-related variables
- Fix typing errors
- `bin/init-overlay` targets the right OVERLAYS_HOME

[Unreleased]: https://github.com/openfun/jitsi-k8s
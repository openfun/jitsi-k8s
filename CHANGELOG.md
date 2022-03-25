# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Terraform project to create a K8S cluster on scaleway
- Kustomize project to deploy jitsi on K8S
- Example to override images name and tag
- Avoid disturbing conferences when shutting down JVB
- Autoscale JVB pool
- Deploy JVB exporter and podmonitor
- Deploy Jitsi dashboards on Grafana
- Add dynamic pod deletion cost on JVB
- Resource requests and limits on each pod
- Documentation on the choices made in this repo
- Documentation on Octo
- Documentation on jvb services and ports
- Documentation on prosody tests
- Autoscale frontend
- Configure cluster autoscaler

### Fixed

- Fix password generation on macos
- Fix `k8s-apply-config` in Makefile for macos users
- Merge `cert-issuer` related files in base and overlays
- Change default octo bridge selection strategy from SplitBridge to SingleBridge
- Overlays template initializes all domain-related variables
- Fix various typing errors
- `bin/init-overlay` targets the right OVERLAYS_HOME
- Fix typos in `jibri_status` documentation

## Changed

- Rework env to make it easy to add jwt authentication
- Autoscale JVB pool according to network usage
- Octo strategy is now RegionBased by default
- Use statefulset instead of deployment for jvb
- Autoscale JVB pool according to CPU

[Unreleased]: https://github.com/openfun/jitsi-k8s
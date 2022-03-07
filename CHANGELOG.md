# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Autoscale JVB pool according to network utilization

### Added

- Autoscale JVB pool

### Fixed

- Security issue with metacontroller permissions over kubernetes API

### Fixed

- Run `make k8s-apply-config` only one time to apply the entire k8s configuration

### Added

- Avoid disturbing conferences when shutting down JVB

### Added

- Import metacontroller from Github
- Dynamicaly create and destroy JVB services linked to created and destroyed JVB pod

### Added

- Variabilize domain name to create several k8s clusters on several workspaces

### Added

- Allow developper to create several namespaces

### Added

- Terraform project to create a K8S cluster on scaleway
- Kustomize project to deploy jitsi on K8S
- Deploy metacontroller with helm

### Changed

- Upgrade helm terraform provider

[Unreleased]: https://github.com/openfun/jitsi-k8s
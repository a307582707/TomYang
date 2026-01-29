# Contributing

Thanks for considering a contribution!

## Scope
This repository contains Kubernetes manifests, systemd units, and helper scripts.
Keep changes focused and aligned with the existing layout.

## Workflow
1. Create a feature branch from the default branch.
2. Make small, reviewable changes.
3. Update documentation when behavior changes.
4. Open a pull request with a clear summary and testing notes.

## Validation (recommended)
- Render any `{{ ... }}` placeholders before validation.
- Validate YAML schema with `kubeconform` or `kubeval` if available.
- Use `kubectl apply --dry-run=client -f <file>` on a compatible cluster.

## Style
- Keep YAML indentation at 2 spaces.
- Prefer explicit values over implicit defaults.

## Commit messages
Use short, imperative summaries (e.g. "Add coredns service monitor").

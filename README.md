# TomYang Kubernetes Manifests

Reference manifests and systemd units for a self-managed Kubernetes v1.11.x
cluster. This repository includes control-plane static Pod manifests, node
configuration, PKI templates, and common addons.

## Highlights
- HA control-plane with Keepalived + HAProxy and a VIP
- Static Pod manifests for core control-plane components
- etcd configuration and TLS material templates
- CNI options: Calico or Flannel
- Addons: CoreDNS, Metrics Server, Dashboard, EFK, Prometheus stack, Ingress,
  External DNS, Weave Scope
- Helper scripts for image sync and platform integration

## Repository layout
```
k8s/
  addons/         Baseline cluster addons (CNI, DNS, metrics, proxy)
  ExtraAddons/    Optional components (dashboard, EFK, Prometheus, ingress)
  master/         Control-plane manifests, systemd units, and configs
  node/           Node kubelet configs and systemd units
  pki/            CFSSL JSON templates for certificates
pull.sh           Image sync helper for gcr.io/quay.io
vsphere.sh        vSphere helper script (optional)
```

## Prerequisites (high level)
- Linux hosts for control-plane and nodes
- Container runtime (Docker) and kubelet installed on each host
- etcd cluster (see k8s/master/etc/etcd)
- VIP with Keepalived + HAProxy
- CNI binaries in /opt/cni/bin

## Quick start (high level)
1. Generate certificates from `k8s/pki` and place them under `/etc/kubernetes/pki`.
2. Render placeholder values (e.g. `{{ VIP }}`, `{{ etcd_servers }}`) in manifests.
3. Install systemd units under `k8s/master/systemd` and `k8s/node/systemd`.
4. Apply control-plane static Pod manifests under `k8s/master/manifests`.
5. Apply a CNI addon (Calico or Flannel) from `k8s/addons`.
6. Install optional addons from `k8s/ExtraAddons` as needed.

## Configuration notes
- Templates use `{{ ... }}` placeholders. Replace them before deployment.
- Images currently reference Kubernetes v1.11.1 and `pause:3.1`. Update image
  tags if you target a newer version.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security
See [SECURITY.md](SECURITY.md) for reporting guidance.

# runtime — 节点运行时基线

历史 `k8s/*/etc/kubelet/kubelet-conf.yml` 使用 `cgroupDriver: cgroupfs` 与 Docker 时代假设。
现代节点请使用 **containerd（或 CRI-O）+ systemd cgroup**。

## 核对项

1. kubelet `cgroupDriver: systemd`
2. containerd `SystemdCgroup = true`（对应 runtime 配置）
3. kubelet `--container-runtime-endpoint=unix:///run/containerd/containerd.sock`
4. 停用 dockershim / 不要挂载 Docker socket 到业务/排障 Pod
5. 镜像仓库：私有 mirror + digest 钉扎

## 样例片段

见 `containerd-config.toml.snippet` 与 `kubelet-config.snippet.yml`（**片段，非完整生产配置**）。

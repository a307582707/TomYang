# runtime — 节点运行时基线

历史 `k8s/*/etc/kubelet/kubelet-conf.yml` 使用 `cgroupDriver: cgroupfs` 与 Docker 时代假设。
现代节点请使用 **containerd（或 CRI-O）+ systemd cgroup**。

## 核对项

1. kubelet `cgroupDriver: systemd`
2. containerd `SystemdCgroup = true`（对应 runtime 配置）
3. kubelet `--container-runtime-endpoint=unix:///run/containerd/containerd.sock`
4. 停用 dockershim / 不要挂载 Docker socket 到业务/排障 Pod
5. 镜像仓库：私有 mirror + digest 钉扎；`sandbox_image` 指向现网 pause
6. `readOnlyPort: 0`；匿名认证关闭；webhook 鉴权开启

## 样例片段

| 文件 | 内容 |
|------|------|
| `containerd-config.toml.snippet` | CRI、systemd cgroup、registry、metrics 地址 |
| `kubelet-config.snippet.yml` | KubeletConfiguration：DNS、驱逐、TLS bootstrap 提示 |

均为**片段，非完整生产配置**。替换 `{{ PLACEHOLDER }}` 后与发行版文档合并。

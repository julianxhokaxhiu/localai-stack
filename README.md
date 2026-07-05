# localai-stack

Docker Compose stack for Lemonade Server/Open WebUI/SearXNG with support for CPUs, AMD, Nvidia, Intel GPUs and NPU hardware.

## Prerequisites

- Docker Engine with Compose plugin (`docker compose`)
- GNU Make (`make`)
- Linux (native or WSL)

## Compose Layering Model

Every command is built from:

- Base (OpenWebUI + Lemonade + SearXNG): `docker-compose.common.yml`
- Platform (AMD):
  - Native Linux AMD: `docker-compose.gpu.amd.yml`
  - AMD on WSL: `docker-compose.gpu.amd.wsl.yml`
- Backend:
  - CPU: `docker-compose.backend.cpu.yml`
  - ROCm: `docker-compose.backend.rocm.yml`
  - Vulkan: `docker-compose.backend.vulkan.yml`
  - CUDA: `docker-compose.backend.cuda.yml`
- Platform (NVIDIA):
  - Native NVIDIA: `docker-compose.gpu.nvidia.yml`
  - NVIDIA on WSL: `docker-compose.gpu.nvidia.wsl.yml`
- Optional overlay:
  - NPU passthrough: `docker-compose.npu.yml`

## Device Mapping

Device paths are layered automatically by compose overlay:

- ROCm backend: `/dev/kfd`
- Vulkan backend: `/dev/dri`
- CUDA backend: NVIDIA GPU runtime
- NPU overlay: `/dev/accel/accel0`

## AMD Combinations (All Cases)

### 1) Native AMD + ROCm

Start:

```bash
make up-amd-rocm
```

Stop:

```bash
make down-amd-rocm
```

### 2) Native AMD + Vulkan

Start:

```bash
make up-amd-vulkan
```

Stop:

```bash
make down-amd-vulkan
```

### 3) Native AMD + ROCm + NPU

Start:

```bash
make up-amd-rocm-npu
```

Stop:

```bash
make down-amd-rocm-npu
```

### 4) Native AMD + Vulkan + NPU

Start:

```bash
make up-amd-vulkan-npu
```

Stop:

```bash
make down-amd-vulkan-npu
```

### 5) WSL AMD + ROCm

Start:

```bash
make up-wsl-rocm
```

Stop:

```bash
make down-wsl-rocm
```

### 6) WSL AMD + Vulkan

Start:

```bash
make up-wsl-vulkan
```

Stop:

```bash
make down-wsl-vulkan
```

### 7) WSL AMD + ROCm + NPU

Start:

```bash
make up-wsl-rocm-npu
```

Stop:

```bash
make down-wsl-rocm-npu
```

### 8) WSL AMD + Vulkan + NPU

Start:

```bash
make up-wsl-vulkan-npu
```

Stop:

```bash
make down-wsl-vulkan-npu
```

### 9) WSL NVIDIA + CUDA

Start:

```bash
make up-wsl-cuda
```

Stop:

```bash
make down-wsl-cuda
```

### 10) Native NVIDIA + CUDA

Start:

```bash
make up-nvidia
```

Stop:

```bash
make down-nvidia
```

## Useful Operations

Show running services:

```bash
make ps
```

Follow logs for active AMD stack:

```bash
make logs-amd-rocm
# or logs-amd-vulkan, logs-amd-rocm-npu, logs-amd-vulkan-npu
# or logs-wsl-rocm, logs-wsl-vulkan, logs-wsl-rocm-npu, logs-wsl-vulkan-npu
```

Follow logs for NVIDIA stack:

```bash
make logs-nvidia
```

Follow logs for WSL CUDA stack:

```bash
make logs-wsl-cuda
```

Render merged Compose config:

```bash
make config-amd-rocm
# same naming pattern for other AMD targets
make config-wsl-cuda
make config-nvidia
```

Stop and remove stack volumes from base project:

```bash
make purge
```

## Service Endpoint

When the stack is up:

- OpenWebUI is exposed on `http://localhost`
- Lemonade UI is exposed on `http://localhost:13305/`

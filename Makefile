COMPOSE = docker compose
BASE = -f docker-compose.common.yml

# Backend overlays
CPU = -f docker-compose.backend.cpu.yml
ROCM = -f docker-compose.backend.rocm.yml
VULKAN = -f docker-compose.backend.vulkan.yml
CUDA = -f docker-compose.backend.cuda.yml
ROCM_WSL = -f docker-compose.backend.rocm.wsl.yml
VULKAN_WSL = -f docker-compose.backend.vulkan.wsl.yml
CUDA_WSL = -f docker-compose.backend.cuda.wsl.yml

# Accelerator overlays
AMD_NATIVE = -f docker-compose.gpu.amd.yml
AMD_WSL = -f docker-compose.gpu.amd.wsl.yml
NVIDIA_WSL = -f docker-compose.gpu.nvidia.wsl.yml
INTEL = -f docker-compose.gpu.intel.yml
NVIDIA = -f docker-compose.gpu.nvidia.yml
NPU = -f docker-compose.npu.yml

.SILENT:

.PHONY: help pull ps purge \
	update-lemonade-configs \
	up down logs config resolve-stack-target \
	up-cpu down-cpu logs-cpu config-cpu \
	up-amd-rocm down-amd-rocm logs-amd-rocm config-amd-rocm \
	up-amd-vulkan down-amd-vulkan logs-amd-vulkan config-amd-vulkan \
	up-amd-rocm-npu down-amd-rocm-npu logs-amd-rocm-npu config-amd-rocm-npu \
	up-amd-vulkan-npu down-amd-vulkan-npu logs-amd-vulkan-npu config-amd-vulkan-npu \
	up-nvidia down-nvidia logs-nvidia config-nvidia \
	up-wsl-rocm down-wsl-rocm logs-wsl-rocm config-wsl-rocm \
	up-wsl-vulkan down-wsl-vulkan logs-wsl-vulkan config-wsl-vulkan \
	up-wsl-cuda down-wsl-cuda logs-wsl-cuda config-wsl-cuda \
	up-wsl-rocm-npu down-wsl-rocm-npu logs-wsl-rocm-npu config-wsl-rocm-npu \
	up-wsl-vulkan-npu down-wsl-vulkan-npu logs-wsl-vulkan-npu config-wsl-vulkan-npu \
	config-intel \
	up-gpu-rocm down-gpu-rocm logs-gpu-rocm config-gpu-rocm \
	up-gpu-vulkan down-gpu-vulkan logs-gpu-vulkan config-gpu-vulkan \
	up-npu-gpu-rocm down-npu-gpu-rocm logs-npu-gpu-rocm config-npu-gpu-rocm \
	up-npu-gpu-vulkan down-npu-gpu-vulkan logs-npu-gpu-vulkan config-npu-gpu-vulkan

help:
	@echo "Compose layering model:"
	@echo "  Base:      docker-compose.common.yml"
	@echo "  Backend:   cpu | rocm | vulkan | cuda"
	@echo "  Platform:  AMD native (docker-compose.gpu.amd.yml) | AMD WSL (docker-compose.gpu.amd.wsl.yml) | NVIDIA native (docker-compose.gpu.nvidia.yml) | NVIDIA WSL (docker-compose.gpu.nvidia.wsl.yml)"
	@echo "  Optional:  NPU overlay (docker-compose.npu.yml)"
	@echo ""
	@echo "Device mapping by overlay:"
	@echo "  ROCm backend   -> /dev/kfd (AMD native) | /dev/dxg (AMD WSL)"
	@echo "  Vulkan backend -> /dev/dri (AMD native) | /dev/dxg (AMD WSL)"
	@echo "  CUDA backend   -> NVIDIA GPU runtime"
	@echo "  NPU overlay    -> /dev/accel/accel0"
	@echo ""
	@echo "Main targets:"
	@echo "  up | down | logs | config (auto-detect best available stack)"
	@echo "  up-cpu"
	@echo "  up-amd-rocm | up-amd-vulkan"
	@echo "  up-amd-rocm-npu | up-amd-vulkan-npu"
	@echo "  up-nvidia"
	@echo "  up-wsl-rocm | up-wsl-vulkan"
	@echo "  up-wsl-cuda"
	@echo "  up-wsl-rocm-npu | up-wsl-vulkan-npu"
	@echo ""
	@echo "Auto-detection priority:"
	@echo "  Native: AMD ROCm+NPU > AMD ROCm > NVIDIA CUDA > AMD Vulkan+NPU > AMD Vulkan > CPU"
	@echo "  WSL:    NVIDIA CUDA > AMD ROCm+NPU > AMD ROCm > CPU"
	@echo "  update-lemonade-configs"

update-lemonade-configs:
	./utils/update_lemonade_configs.sh

pull:
	$(COMPOSE) $(BASE) pull

ps:
	$(COMPOSE) $(BASE) ps

purge:
	$(COMPOSE) $(BASE) down -v --remove-orphans

# Prints the best stack target for ACTION=up|down|logs|config (defaults to up).
resolve-stack-target:
	@action="$(if $(ACTION),$(ACTION),up)"; \
	is_wsl=0; \
	if [ -n "$$WSL_INTEROP" ] || \
		grep -qiE "(microsoft|wsl)" /proc/sys/kernel/osrelease 2>/dev/null || \
		grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then \
		is_wsl=1; \
	fi; \
	has_npu=0; [ -e /dev/accel/accel0 ] && has_npu=1; \
	has_rocm=0; [ -e /dev/kfd ] && has_rocm=1; \
	has_vulkan=0; [ -d /dev/dri ] && has_vulkan=1; \
	has_dxg=0; [ -e /dev/dxg ] && has_dxg=1; \
	has_nvidia=0; \
	if command -v nvidia-smi >/dev/null 2>&1 || [ -e /dev/nvidiactl ] || [ -e /proc/driver/nvidia/version ]; then \
		has_nvidia=1; \
	fi; \
	target="$$action-cpu"; \
	if [ "$$is_wsl" -eq 1 ]; then \
		if [ "$$has_nvidia" -eq 1 ]; then \
			target="$$action-wsl-cuda"; \
		elif [ "$$has_dxg" -eq 1 ]; then \
			if [ "$$has_npu" -eq 1 ]; then \
				target="$$action-wsl-rocm-npu"; \
			else \
				target="$$action-wsl-rocm"; \
			fi; \
		fi; \
	else \
		if [ "$$has_rocm" -eq 1 ]; then \
			if [ "$$has_npu" -eq 1 ]; then \
				target="$$action-amd-rocm-npu"; \
			else \
				target="$$action-amd-rocm"; \
			fi; \
		elif [ "$$has_nvidia" -eq 1 ]; then \
			target="$$action-nvidia"; \
		elif [ "$$has_vulkan" -eq 1 ]; then \
			if [ "$$has_npu" -eq 1 ]; then \
				target="$$action-amd-vulkan-npu"; \
			else \
				target="$$action-amd-vulkan"; \
			fi; \
		fi; \
	fi; \
	echo "$$target"

up:
	@target="$$($(MAKE) --no-print-directory resolve-stack-target ACTION=up)"; \
	echo "Auto-selected target: $$target"; \
	$(MAKE) --no-print-directory "$$target"

down:
	@target="$$($(MAKE) --no-print-directory resolve-stack-target ACTION=down)"; \
	echo "Auto-selected target: $$target"; \
	$(MAKE) --no-print-directory "$$target"

logs:
	@target="$$($(MAKE) --no-print-directory resolve-stack-target ACTION=logs)"; \
	echo "Auto-selected target: $$target"; \
	$(MAKE) --no-print-directory "$$target"

config:
	@target="$$($(MAKE) --no-print-directory resolve-stack-target ACTION=config)"; \
	echo "Auto-selected target: $$target"; \
	$(MAKE) --no-print-directory "$$target"

# CPU
up-cpu:
	$(COMPOSE) $(BASE) $(CPU) up -d

down-cpu:
	$(COMPOSE) $(BASE) $(CPU) down

logs-cpu:
	$(COMPOSE) $(BASE) $(CPU) logs -f

config-cpu:
	$(COMPOSE) $(BASE) $(CPU) config

# AMD native + backend
up-amd-rocm:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(ROCM) up -d

down-amd-rocm:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(ROCM) down

logs-amd-rocm:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(ROCM) logs -f

config-amd-rocm:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(ROCM) config

up-amd-vulkan:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(VULKAN) up -d

down-amd-vulkan:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(VULKAN) down

logs-amd-vulkan:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(VULKAN) logs -f

config-amd-vulkan:
	$(COMPOSE) $(BASE) $(AMD_NATIVE) $(VULKAN) config

# AMD native + NPU + backend
up-amd-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(ROCM) up -d

down-amd-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(ROCM) down

logs-amd-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(ROCM) logs -f

config-amd-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(ROCM) config

up-amd-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(VULKAN) up -d

down-amd-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(VULKAN) down

logs-amd-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(VULKAN) logs -f

config-amd-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_NATIVE) $(VULKAN) config

# NVIDIA + CUDA backend
up-nvidia:
	$(COMPOSE) $(BASE) $(NVIDIA) $(CUDA) up -d

down-nvidia:
	$(COMPOSE) $(BASE) $(NVIDIA) $(CUDA) down

logs-nvidia:
	$(COMPOSE) $(BASE) $(NVIDIA) $(CUDA) logs -f

config-nvidia:
	$(COMPOSE) $(BASE) $(NVIDIA) $(CUDA) config

# AMD WSL + backend
up-wsl-rocm:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(ROCM_WSL) up -d

down-wsl-rocm:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(ROCM_WSL) down

logs-wsl-rocm:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(ROCM_WSL) logs -f

config-wsl-rocm:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(ROCM_WSL) config

up-wsl-vulkan:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(VULKAN_WSL) up -d

down-wsl-vulkan:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(VULKAN_WSL) down

logs-wsl-vulkan:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(VULKAN_WSL) logs -f

config-wsl-vulkan:
	$(COMPOSE) $(BASE) $(AMD_WSL) $(VULKAN_WSL) config

up-wsl-cuda:
	$(COMPOSE) $(BASE) $(NVIDIA_WSL) $(CUDA_WSL) up -d

down-wsl-cuda:
	$(COMPOSE) $(BASE) $(NVIDIA_WSL) $(CUDA_WSL) down

logs-wsl-cuda:
	$(COMPOSE) $(BASE) $(NVIDIA_WSL) $(CUDA_WSL) logs -f

config-wsl-cuda:
	$(COMPOSE) $(BASE) $(NVIDIA_WSL) $(CUDA_WSL) config

# AMD WSL + NPU + backend
up-wsl-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(ROCM_WSL) up -d

down-wsl-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(ROCM_WSL) down

logs-wsl-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(ROCM_WSL) logs -f

config-wsl-rocm-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(ROCM_WSL) config

up-wsl-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(VULKAN_WSL) up -d

down-wsl-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(VULKAN_WSL) down

logs-wsl-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(VULKAN_WSL) logs -f

config-wsl-vulkan-npu:
	$(COMPOSE) $(BASE) $(NPU) $(AMD_WSL) $(VULKAN_WSL) config

config-intel:
	$(COMPOSE) $(BASE) $(INTEL) config

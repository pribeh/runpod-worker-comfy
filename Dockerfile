FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 AS base

# Set environment variables to avoid interactive prompts and optimize installation
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies, including libGL for OpenCV issues
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip to the latest version
RUN pip3 install --upgrade pip

# Clone the ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Set working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies and RunPod libraries
RUN pip3 install --upgrade --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir -r requirements.txt \
    && pip3 install --no-cache-dir runpod requests gguf

# Add retry logic for git clone operations to handle flaky downloads
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install GGUF Node and dependencies
RUN git clone https://github.com/city96/ComfyUI-GGUF.git custom_nodes/ComfyUI-GGUF \
    && echo "Installed: ComfyUI-GGUF" \
    && pip3 install gguf

# Install ComfyUI NSFW Detection Node
RUN git clone https://github.com/katalist-ai/comfyUI-nsfw-detection.git custom_nodes/ComfyUI-nsfw-detection \
    && echo "Installed: ComfyUI-nsfw-detection" \
    && if [ -f custom_nodes/ComfyUI-nsfw-detection/requirements.txt ]; then \
        pip3 install -r custom_nodes/ComfyUI-nsfw-detection/requirements.txt || echo "Failed to install NSFW detection dependencies"; \
    else \
        echo "No requirements.txt for NSFW detection node"; \
    fi

# Install ComfyUI essentials
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git custom_nodes/ComfyUI_essentials \
    && echo "Installed: ComfyUI_essentials" \
    && if [ -f custom_nodes/ComfyUI_essentials/requirements.txt ]; then \
        pip3 install -r custom_nodes/ComfyUI_essentials/requirements.txt || echo "Failed to install ComfyUI_essentials dependencies"; \
    else \
        echo "No requirements.txt for ComfyUI_essentials"; \
    fi

# Verify custom nodes are installed
RUN ls -lh /comfyui/custom_nodes/

# Add network volume support
ADD src/extra_model_paths.yaml ./

# Return to the root directory
WORKDIR /

# Add start scripts and handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Stage 2: Download Models
FROM base AS downloader

ARG HUGGINGFACE_ACCESS_TOKEN
ARG MODEL_TYPE

WORKDIR /comfyui

# Copy locally downloaded models
COPY models/loras/ /comfyui/models/loras/

# Download additional models from Hugging Face
RUN wget -O models/unet/flux1-schnell-Q8_0.gguf https://huggingface.co/city96/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-Q8_0.gguf \
    && wget -O models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors \
    && wget -O models/clip/clip_l.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors \
    && wget -O models/vae/ae.safetensors https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors

# Verify downloaded models
RUN ls -lh models/clip/ models/unet/ models/vae/ models/loras/

# Stage 3: Final Image
FROM base AS final

# Copy models from downloader stage to the final image
COPY --from=downloader /comfyui/models /comfyui/models

# Start the container
CMD ["./start.sh"]

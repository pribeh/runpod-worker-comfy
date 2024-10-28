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

# Install Comfyroll Studio with transformers library
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git custom_nodes/Comfyroll-Studio \
    && echo "Installed: Comfyroll-Studio" \
    && pip3 install transformers

# Install Impact-Pack with dependencies, including 'ultralytics'
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git custom_nodes/Impact-Pack \
    && echo "Installed: Impact-Pack" \
    && if [ -f custom_nodes/Impact-Pack/requirements.txt ]; then \
        pip3 install -r custom_nodes/Impact-Pack/requirements.txt || echo "Failed to install Impact-Pack dependencies"; \
    else \
        echo "No requirements.txt for Impact-Pack"; \
    fi \
    && pip3 install numpy pillow ultralytics  # Ensure necessary libraries are installed

# Run the install.py script for Impact-Pack
RUN if [ -f custom_nodes/Impact-Pack/install.py ]; then \
        python3 custom_nodes/Impact-Pack/install.py || echo "Failed to run Impact-Pack install.py"; \
    else \
        echo "No install.py found for Impact-Pack"; \
    fi

RUN git clone https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git custom_nodes/Derfuu-ModdedNodes \
    && echo "Installed: Derfuu-ModdedNodes" \
    && [ -f custom_nodes/Derfuu-ModdedNodes/requirements.txt ] && pip3 install -r custom_nodes/Derfuu-ModdedNodes/requirements.txt || echo "No requirements.txt for Derfuu"

# Clone WAS Node Suite and install dependencies with system Python
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git custom_nodes/WAS-Node-Suite \
    && echo "Installed: WAS-Node-Suite" \
    && if [ -f custom_nodes/WAS-Node-Suite/requirements.txt ]; then \
        pip3 install -r custom_nodes/WAS-Node-Suite/requirements.txt || echo "Failed to install WAS-Node-Suite dependencies"; \
    else \
        echo "No requirements.txt for WAS-Node-Suite"; \
    fi \
    && pip3 uninstall -y opencv-python opencv-python-headless[ffmpeg] \
    && pip3 install opencv-python-headless[ffmpeg]

RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git custom_nodes/Custom-Scripts \
    && echo "Installed: Custom-Scripts" \
    && [ -f custom_nodes/Custom-Scripts/requirements.txt ] && pip3 install -r custom_nodes/Custom-Scripts/requirements.txt || echo "No requirements.txt for Custom Scripts"

# Install Art-Venture and handle OpenCV issues
RUN git clone https://github.com/sipherxyz/comfyui-art-venture.git custom_nodes/Art-Venture \
    && echo "Installed: Art-Venture" \
    && pip3 install opencv-python-headless[ffmpeg]

# Install SDXL Prompt Styler with Hugging Face dependencies
RUN git clone https://github.com/twri/sdxl_prompt_styler.git custom_nodes/SDXL-Prompt-Styler \
    && echo "Installed: SDXL-Prompt-Styler" \
    && pip3 install diffusers transformers

# Install Copilot Node with OpenAI dependency
RUN git clone https://github.com/hylarucoder/comfyui-copilot.git custom_nodes/Copilot \
    && echo "Installed: Copilot" \
    && pip3 install openai

# Install RGThree Node and ensure all requirements are satisfied
RUN git clone https://github.com/rgthree/rgthree-comfy.git custom_nodes/RGThree \
    && echo "Installed: RGThree" \
    && [ -f custom_nodes/RGThree/requirements.txt ] && pip3 install -r custom_nodes/RGThree/requirements.txt

# Install Crystools Node
RUN git clone https://github.com/crystian/ComfyUI-Crystools.git custom_nodes/Crystools \
    && echo "Installed: Crystools" \
    && [ -f custom_nodes/Crystools/requirements.txt ] && pip3 install -r custom_nodes/Crystools/requirements.txt

# Install Universal-Styler with Hugging Face dependencies
RUN git clone https://github.com/KoreTeknology/ComfyUI-Universal-Styler.git custom_nodes/Universal-Styler \
    && echo "Installed: Universal-Styler" \
    && pip3 install diffusers transformers

# Install ComfyUI essentials
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git custom_nodes/ComfyUI_essentials \
    && echo "Installed: ComfyUI_essentials" \
    && if [ -f custom_nodes/ComfyUI_essentials/requirements.txt ]; then \
        pip3 install -r custom_nodes/ComfyUI_essentials/requirements.txt || echo "Failed to install ComfyUI_essentials dependencies"; \
    else \
        echo "No requirements.txt for ComfyUI_essentials"; \
    fi

# Install DJZ-Nodes with error handling and pip installation verification
RUN git clone https://github.com/MushroomFleet/DJZ-Nodes.git custom_nodes/DJZ-Nodes \
    && echo "Installed: DJZ-Nodes" \
    && if [ -f custom_nodes/DJZ-Nodes/requirements.txt ]; then \
        pip3 install -r custom_nodes/DJZ-Nodes/requirements.txt || echo "Failed to install DJZ-Nodes dependencies"; \
    else \
        echo "No requirements.txt for DJZ-Nodes"; \
    fi \
    && pip3 check || echo "Some dependencies are not satisfied"

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

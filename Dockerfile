# Start from a clean base image
FROM runpod/worker-comfyui:5.8.5-base

# Install custom nodes using comfy-cli 
# See Comfy Registry to find the correct name
# RUN comfy-node-install comfyui-kjnodes comfyui-ic-light

# Optional cached model links.
# Runpod should provide MODEL_NAME from Endpoint Model setting.
# Current setup links Flux UNet from cached snapshot into:
#   /comfyui/models/unet/flux-2-klein-9b-fp8.safetensors
# (You can disable this path by commenting one line in handler.py.)
#
# IMPORTANT: `CACHED_MODEL_FILENAME` and `CACHED_MODEL_TARGET_DIR` are required.
# If you want to cache another component (for example VAE/CLIP instead of UNET),
# change these ENV values here (single source of truth).
ENV HF_CACHE_ROOT=/runpod-volume/huggingface-cache/hub
ENV CACHED_MODEL_FILENAME=flux-2-klein-9b-fp8.safetensors
ENV CACHED_MODEL_TARGET_DIR=models/unet

# Download models using comfy-cli:
RUN comfy model download --url "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
  --relative-path models/clip --filename qwen_3_8b_fp8mixed.safetensors
RUN comfy model download --url "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
  --relative-path models/vae --filename flux2-vae.safetensors

# Keep the original upstream handler so the adapter can delegate to it.
RUN cp /handler.py /handler_base.py

# Replace only the public input contract, preserve the proven execution path.
COPY cached_model_links.py /cached_model_links.py
COPY handler.py /handler.py

# Copy local static input files into the ComfyUI input directory
# COPY input/ /comfyui/input/
COPY workflow/workflow_api.json /workflow/workflow_api.json
COPY input/costume.png /comfyui/input/costume.png

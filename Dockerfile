# start from a clean base image
FROM runpod/worker-comfyui:5.8.5-base

# install custom nodes using comfy-cli 
# see Comfy Registry to find the correct name
# RUN comfy-node-install comfyui-kjnodes comfyui-ic-light

# download models using comfy-cli (disabled by default because we use network storage):
# Flux UNet is gated on Hugging Face. You must:
# 1) accept license terms at:
#    https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8
# 2) use HF_TOKEN with read access (for RunPod, set it in Endpoint Secrets/Env).
#  
# ARG HF_API_TOKEN
# RUN comfy model download --url "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" \
#   --relative-path models/unet --filename flux-2-klein-9b-fp8.safetensors --set-hf-api-token "${HF_API_TOKEN}"
# RUN comfy model download --url "https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" \
#   --relative-path models/clip --filename qwen_3_8b_fp8mixed.safetensors
# RUN comfy model download --url "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors" \
#   --relative-path models/vae --filename flux2-vae.safetensors

# Keep the original upstream handler so the adapter can delegate to it.
RUN cp /handler.py /handler_base.py

# Replace only the public input contract, preserve the proven execution path.
COPY handler.py /handler.py

# Copy local static input files into the ComfyUI input directory
#COPY input/ /comfyui/input/
COPY workflow/workflow_api.json /workflow/workflow_api.json
COPY input/costume.png /comfyui/input/costume.png

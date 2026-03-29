# Simplified worker-comfyui wrapper

Single purpose adapter:
- takes one input image from request,
- injects fixed workflow,
- uses baked `costume.png` as Image 2,
- delegates execution to upstream `handler_base.py`.

`costume.png` is auto-used by workflow node `246` (`LoadImage`) because the file is copied to `/comfyui/input/costume.png` during build.

## Requirements

- **GPU**: NVIDIA GPU with CUDA 12.6 or higher support.
- **Runtime**: RunPod Serverless with `runpod/worker-comfyui:5.8.5-base`.


## Request

Required payload:
- `input.image` (string): source image as Base64 Data URI (recommended format: `data:image/png;base64,...`).

Minimal request example:
```json
{
  "input": {
    "image": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

`handler.py` only adapts this payload into fixed `workflow + images` format and delegates execution to upstream `worker-comfyui`.

## Response

- Response is returned from upstream `worker-comfyui` without custom post-processing in this adapter.
- Main result is in `output.images[]`:
  - `data`: Base64 image payload
  - `filename`: generated file name
  - `type`: typically `base64`
- Useful top-level fields from Runpod job response: `id`, `status`, `delayTime`, `executionTime`, `workerId`.

Example (truncated):
```json
{
  "id": "....",
  "output": {
    "images": [
      {
        "data": "iVBORw0KGgoAAAANSUhEUgAA...",
        "filename": "costume_00001_.png",
        "type": "base64"
      }
    ]
  },
  "status": "COMPLETED",
  "delayTime": 15741,
  "executionTime": 43377,
  "workerId": "..."
}
```

## Workflow
<img width="1920" height="903" alt="Housemaid" src="https://github.com/user-attachments/assets/b8379044-236b-4f3f-ac31-86d345d6a24c" />

## Results

| Input | Output |
|------|--------|
| ![Ri](https://github.com/user-attachments/assets/77141973-748c-4bf1-a1a1-171f95c93681) | <img width="880" height="1168" alt="Flux2-Klein_00002_" src="https://github.com/user-attachments/assets/2dc48fcf-9338-4725-985f-04d761b8211d" /> |
| ![Di](https://github.com/user-attachments/assets/8c2c2fac-d9bd-4562-b3fc-2859449181ae) | <img width="1248" height="832" alt="Flux2-Klein_00001_" src="https://github.com/user-attachments/assets/58684ca4-e4f7-4357-aa47-56337da5c6e6" /> |


## Workflow model files

- Node `252` (`UNETLoader`): `flux-2-klein-9b-fp8.safetensors` -> `/comfyui/models/unet/`
- Node `251` (`CLIPLoader`): `qwen_3_8b_fp8mixed.safetensors` -> `/comfyui/models/clip/`
- Node `236` (`VAELoader`): `flux2-vae.safetensors` -> `/comfyui/models/vae/`

## Model sourcing paths

1. Baked into Docker image (`comfy model download` in `Dockerfile`)
- Used now for:
  - `qwen_3_8b_fp8mixed.safetensors` -> `/comfyui/models/clip/`
  - `flux2-vae.safetensors` -> `/comfyui/models/vae/`

2. Runpod Cached Models (`Model` in endpoint settings)
- Used now for:
  - `black-forest-labs/FLUX.2-klein-9b-fp8` -> linked to `/comfyui/models/unet/flux-2-klein-9b-fp8.safetensors`
- Required format in Runpod Endpoint -> `Model`:
  - Use Hugging Face repo id in format `org/name` (for example `black-forest-labs/FLUX.2-klein-9b-fp8`).
  - Do not use full file URL here.
- Gated model token:
  - For gated repos (including `black-forest-labs/FLUX.2-klein-9b-fp8`), add your Hugging Face access token in Endpoint configuration (Model token/access token field).
  - Recommended: store the same token as endpoint secret `HUGGINGFACE_ACCESS_TOKEN` for consistency with project docs.
- Runtime linker params:
  - `MODEL_NAME` (comes from Endpoint `Model`, expected `org/name`)
  - `CACHED_MODEL_FILENAME` (required; exact file name inside cached snapshot; can include subpath if needed)
  - `CACHED_MODEL_TARGET_DIR` (required; path inside `/comfyui`, for example `models/unet`)
- Project convention: set these two values in `Dockerfile` as the single source of truth.
- Runtime linker reads cache from `/runpod-volume/huggingface-cache/hub/models--<org>--<repo>/snapshots/<hash>/`.
- This path is optional; to disable it, comment out `link_cached_model_for_comfyui()` in `handler.py`.

3. Network Volume (alternative)
- Supported by `worker-comfyui` extra model paths on Runpod network storage.
- Keep this structure in network storage:
  - `models/clip`
  - `models/vae`
  - `models/unet`

Current project setup uses paths `1` + `2`.

## License note for FLUX.2 [klein] 9B

- The model `black-forest-labs/FLUX.2-klein-9b-fp8` is gated and marked as `flux-non-commercial-license` on Hugging Face.
- If you distribute model weights or derivatives, review the FLUX Non-Commercial License conditions about including the license text and attribution notice.
- For commercial or production use of FLUX [dev]/9B family, request a commercial license from Black Forest Labs.
- This repository does not redistribute FLUX weights directly; weights are loaded from Runpod cached model storage at runtime.
- Full license text: [black-forest-labs/FLUX.2-klein-9b-fp8/LICENSE.md](https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/blob/main/LICENSE.md)

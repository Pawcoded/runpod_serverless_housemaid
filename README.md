# Simplified worker-comfyui wrapper

Single purpose adapter:
- takes one input image from request,
- injects fixed workflow,
- uses baked `costume.png` as Image 2,
- delegates execution to upstream `handler_base.py`.

`costume.png` is auto-used by workflow node `246` (`LoadImage`) because the file is copied to `/comfyui/input/costume.png` during build.

## Request format

```json
{
  "input": {
    "image": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

## Workflow model files

- Node `252` (`UNETLoader`): `flux-2-klein-9b-fp8.safetensors` -> `/comfyui/models/unet/`
- Node `251` (`CLIPLoader`): `qwen_3_8b_fp8mixed.safetensors` -> `/comfyui/models/clip/`
- Node `236` (`VAELoader`): `flux2-vae.safetensors` -> `/comfyui/models/vae/`

Flux note:
- `flux-2-klein-9b-fp8.safetensors` is gated on Hugging Face and requires `HF_TOKEN`. For RunPod Endpoint: set `HF_TOKEN` in Endpoint Secrets/Environment (runtime).

- Model download commands in `Dockerfile` are disabled by default.
- Default flow: models are taken from network storage using base `worker-comfyui` extra model paths.
- Keep this folder structure in network storage:
  - `models/clip`
  - `models/vae`
  - `models/unet`
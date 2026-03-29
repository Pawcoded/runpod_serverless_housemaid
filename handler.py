import copy
import json

import runpod

from cached_model_links import link_cached_model_for_comfyui

WORKFLOW_PATH = "/workflow/workflow_api.json"
REQUEST_IMAGE_NAME = "request.png"

# Optional cached-model linking.
# Comment out the next line to rely only on baked-in models and/or network volume.
link_cached_model_for_comfyui()

with open(WORKFLOW_PATH, "r", encoding="utf-8") as f:
    WORKFLOW_TEMPLATE = json.load(f)

import handler_base as base


def handler(job):
    image_payload = job["input"]["image"]

    adapted_job = dict(job)
    adapted_job["input"] = {
        "workflow": copy.deepcopy(WORKFLOW_TEMPLATE),
        "images": [{"name": REQUEST_IMAGE_NAME, "image": image_payload}],
    }

    return base.handler(adapted_job)


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})

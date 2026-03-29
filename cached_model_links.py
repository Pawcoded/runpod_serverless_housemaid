import os
import shutil
from pathlib import Path

HF_CACHE_ROOT = Path(os.environ.get("HF_CACHE_ROOT", "/runpod-volume/huggingface-cache/hub"))
MODEL_NAME = os.environ.get("MODEL_NAME", "").strip()
CACHED_MODEL_FILENAME = os.environ["CACHED_MODEL_FILENAME"].strip()
CACHED_MODEL_TARGET_DIR = os.environ["CACHED_MODEL_TARGET_DIR"].strip()


def resolve_snapshot_path(model_name: str) -> Path:
    if "/" not in model_name:
        raise ValueError(f"MODEL_NAME '{model_name}' must be in 'org/name' format")

    org, name = model_name.split("/", 1)
    model_root = HF_CACHE_ROOT / f"models--{org}--{name}"
    refs_main = model_root / "refs" / "main"
    snapshots_dir = model_root / "snapshots"

    if refs_main.is_file():
        snapshot_hash = refs_main.read_text(encoding="utf-8").strip()
        candidate = snapshots_dir / snapshot_hash
        if candidate.is_dir():
            return candidate

    if snapshots_dir.is_dir():
        versions = sorted([path for path in snapshots_dir.iterdir() if path.is_dir()])
        if versions:
            return versions[0]

    raise RuntimeError(f"Cached model not found for MODEL_NAME={model_name}")


def resolve_target_dir(raw_target_dir: str) -> Path:
    target_dir = Path(raw_target_dir)
    if target_dir.is_absolute():
        return target_dir
    return Path("/comfyui") / raw_target_dir.lstrip("/")


def link_cached_model_for_comfyui():
    if not MODEL_NAME:
        raise RuntimeError("MODEL_NAME is not set. Configure Endpoint Model in Runpod.")
    if not CACHED_MODEL_FILENAME:
        raise RuntimeError("CACHED_MODEL_FILENAME is not set.")

    snapshot_path = resolve_snapshot_path(MODEL_NAME)
    source_file = snapshot_path / CACHED_MODEL_FILENAME
    if not source_file.is_file():
        raise RuntimeError(
            "Cached file not found: "
            f"{source_file}. Check CACHED_MODEL_FILENAME and Endpoint Model."
        )

    target_dir = resolve_target_dir(CACHED_MODEL_TARGET_DIR)
    target_dir.mkdir(parents=True, exist_ok=True)
    target_file = target_dir / CACHED_MODEL_FILENAME

    if target_file.is_symlink():
        try:
            if target_file.resolve() == source_file.resolve():
                return
        except OSError:
            pass
        target_file.unlink()
    elif target_file.exists():
        # Keep existing local file (for example baked model in image).
        return

    try:
        target_file.symlink_to(source_file)
    except OSError:
        shutil.copy2(source_file, target_file)

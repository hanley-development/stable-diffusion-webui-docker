#!/bin/bash

set -Eeuo pipefail

CUSTOM_NODES="/data/config/comfy/custom_nodes"
mkdir -vp "${CUSTOM_NODES}"

declare -A MOUNTS

MOUNTS["/root/.cache"]="/data/.cache"
MOUNTS["${ROOT}/input"]="/data/config/comfy/input"
MOUNTS["${ROOT}/output"]="/output/comfy"

for to_path in "${!MOUNTS[@]}"; do
  set -Eeuo pipefail
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  if [ ! -f "$from_path" ]; then
    mkdir -vp "$from_path"
  fi
  mkdir -vp "$(dirname "${to_path}")"
  ln -sT "${from_path}" "${to_path}"
  echo Mounted $(basename "${from_path}")
done

if [ "${USE_GGUF}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/ComfyUI-GGUF" ] && mv "${ROOT}/ComfyUI-GGUF" "${CUSTOM_NODES}"/
fi
if [ "${USE_XFLUX}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/x-flux-comfyui" ] && mv "${ROOT}/x-flux-comfyui" "${CUSTOM_NODES}"/
  [ ! -e "/data/models/clip_vision" ] && mkdir -p /data/models/clip_vision
  [ ! -e "/data/models/clip_vision/model.safetensors" ] && cd /data/models/clip_vision && \
    python -c 'import sys; from urllib.request import urlopen; from pathlib import Path; Path(sys.argv[2]).write_bytes(urlopen("".join([sys.argv[1],sys.argv[2]])).read())' \
    "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/" "model.safetensors"
  [ ! -e "/data/models/xlabs" ] && mkdir -p /data/models/xlabs/{ipadapters,loras,controlnets}
  [ ! -e "/data/models/xlabs/ipadapters/flux-ip-adapter.safetensors" ] && cd /data/models/xlabs/ipadapters && \
    python -c 'import sys; from urllib.request import urlopen; from pathlib import Path; Path(sys.argv[2]).write_bytes(urlopen("".join([sys.argv[1],sys.argv[2]])).read())' \
    "https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/" "flux-ip-adapter.safetensors"
  [ -d "${ROOT}/models/xlabs" ] && rm -rf "${ROOT}/models/xlabs"
  [ ! -e "${ROOT}/models/xlabs" ] && cd "${ROOT}/models" && ln -sT /data/models/xlabs xlabs && cd ..
fi
if [ "${USE_CNAUX}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/comfyui_controlnet_aux" ] && mv "${ROOT}/comfyui_controlnet_aux" "${CUSTOM_NODES}"/
fi


if [ -f "/data/config/comfy/startup.sh" ]; then
  pushd ${ROOT}
  . /data/config/comfy/startup.sh
  popd
fi

exec "$@"

ARG USE_EDGE=false
# ComfyUI-GGUF support
ARG USE_GGUF=false
# x-flux-comfyui support
ARG USE_XFLUX=false
# comfyui_controlnet_aux support
ARG USE_CNAUX=false

FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

# Use args
ARG USE_EDGE
ARG USE_GGUF
ARG USE_XFLUX
ARG USE_CNAUX

ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1 USE_EDGE=$USE_EDGE
ENV USE_GGUF=$USE_GGUF USE_XFLUX=$USE_XFLUX ROOT=/stable-diffusion
ENV CACHE=/home/app/.cache USE_CNAUX=$USE_CNAUX

RUN apt-get update && apt-get install -y git && ([ "${USE_XFLUX}" = "true" ] && apt-get install -y libgl1-mesa-glx python3-opencv) && apt-get clean
RUN apt-get install -y libgl1-mesa-dev
RUN apt-get install -y libglib2.0-0

ENV ROOT=/stable-diffusion
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone https://github.com/comfyanonymous/ComfyUI.git ${ROOT} && \
  cd ${ROOT} && \
  git checkout master && \
  bash -c 'VERSION=$(git describe --tags --abbrev=0) && \
  if [ "${USE_EDGE}" = "true" ]; then VERSION=$(git describe --abbrev=7); fi && \
  git reset --hard ${VERSION}' && \
  pip install -r requirements.txt
  if [ "${USE_GGUF}" = "true" ]; then \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && git checkout main && \
    pip install -r requirements.txt && cd ..; \
  fi; \
  if [ "${USE_XFLUX}" = "true" ]; then \
    git clone https://github.com/XLabs-AI/x-flux-comfyui.git && \
    cd x-flux-comfyui && git checkout main && \
    pip install -r requirements.txt && cd ..; \
  fi; \
  if [ "${USE_CNAUX}" = "true" ]; then \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    cd comfyui_controlnet_aux && git checkout main && \
    pip install -r requirements.txt && \
    # This extra step to separate onnxruntime installation is required to restore onnx cuda support
    pip install onnxruntime && pip install onnxruntime-gpu && cd ..; \
  fi

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager ${ROOT}/custom_nodes/ComfyUI-Manager && \
  pip install -r ${ROOT}/custom_nodes/ComfyUI-Manager/requirements.txt

WORKDIR ${ROOT}
COPY . /docker/
RUN chmod u+x /docker/entrypoint.sh && cp /docker/extra_model_paths.yaml ${ROOT}

ENV NVIDIA_VISIBLE_DEVICES=all PYTHONPATH="${PYTHONPATH}:${PWD}" CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python -u main.py --listen --port 7860 ${CLI_ARGS}

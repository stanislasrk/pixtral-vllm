# Base image with CUDA and cuDNN support (development version)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Install system packages and Git LFS in a single RUN command
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    wget \
    curl \
    && wget -q https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh \
    && bash script.deb.sh \
    && apt-get install -y git-lfs \
    && git lfs install \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Upgrade pip and install Python packages with no cache
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir \
        numpy \
        torch==2.0.1+cu118 \
        torchvision==0.15.2+cu118 \
        --extra-index-url https://download.pytorch.org/whl/cu118 \
        transformers \
        huggingface_hub \
        vllm \
        mistral_common

# Expose port 8000 for the vLLM server
EXPOSE 8000

# Set up the Hugging Face token at runtime
ENV HUGGINGFACE_TOKEN=${HUGGINGFACE_TOKEN}

# Create the .huggingface directory
RUN mkdir -p /root/.huggingface

# Command to run when the container starts
CMD ["sh", "-c", "echo $HUGGINGFACE_TOKEN > /root/.huggingface/token && chmod 600 /root/.huggingface/token && vllm serve mistralai/Pixtral-12B-2409 --tokenizer_mode mistral --limit_mm_per_prompt 'image=4' --port 8000"]
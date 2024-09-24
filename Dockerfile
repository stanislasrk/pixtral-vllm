# Base image with CUDA and cuDNN support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Install system packages
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Git LFS
RUN apt-get update && \
    wget -q https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh && \
    bash script.deb.sh && \
    apt-get install -y git-lfs && \
    git lfs install && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages with specific versions
RUN pip3 install --upgrade pip && \
    pip3 install \
        numpy \
        torch==1.13.1+cu116 \
        torchvision==0.14.1+cu116 \
        --extra-index-url https://download.pytorch.org/whl/cu116 \
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
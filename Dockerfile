# Base image with CUDA and cuDNN support (development version)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Install system packages, Git LFS, and Docker CLI in a single RUN command
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    wget \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && wget -q https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh \
    && bash script.deb.sh \
    && apt-get install -y git-lfs \
    && git lfs install \
    # Install Docker CLI
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
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

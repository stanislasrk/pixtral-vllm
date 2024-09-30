# Build stage
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as builder

# Install system packages and Python
RUN apt-get update && apt-get install -y \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install Python packages
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
    numpy \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118 \
    transformers \
    huggingface_hub \
    vllm \
    mistral_common

# Runtime stage
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Copy Python and installed packages from builder
COPY --from=builder /usr/local/lib/python3.8 /usr/local/lib/python3.8
COPY --from=builder /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=builder /usr/local/bin/pip3 /usr/local/bin/pip3

# Set up the Hugging Face token at runtime
ENV HUGGINGFACE_TOKEN=${HUGGINGFACE_TOKEN}

# Create the .huggingface directory
RUN mkdir -p /root/.huggingface

# Expose port 8000 for the vLLM server
EXPOSE 8000

# Command to run when the container starts
CMD ["sh", "-c", "echo $HUGGINGFACE_TOKEN > /root/.huggingface/token && chmod 600 /root/.huggingface/token && python3 -m vllm.entrypoints.api_server --model mistralai/Pixtral-12B-2409 --tokenizer_mode mistral --limit_mm_per_prompt 'image=4' --port 8000"]

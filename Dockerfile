# ROCm 7.2 + gfx906 kernels from 6.3 (6.4 dropped gfx906 support)
FROM rocm/dev-ubuntu-22.04:7.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    git \
    cmake \
    build-essential \
    libnuma-dev \
    dpkg-dev \
    hipblas \
    && rm -rf /var/lib/apt/lists/*

ENV ROCM_PATH=/opt/rocm
ENV HIP_PATH=/opt/rocm
ENV PATH=/opt/rocm/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64

# -----------------------------
# Extract gfx906 kernels from ROCm 6.3 rocblas (6.4+ doesn't ship them)
# -----------------------------
WORKDIR /tmp

RUN wget -q https://repo.radeon.com/rocm/apt/6.3/pool/main/r/rocblas/rocblas_4.3.0.60300-39~22.04_amd64.deb -O rocblas63.deb \
 && dpkg-deb -x rocblas63.deb rocblas63

RUN ROCBLAS_LIB="$(find rocblas63 -type d -name library -path '*rocblas*' | head -1)" \
 && mkdir -p /opt/rocm/lib/rocblas/library \
 && cp "$ROCBLAS_LIB"/*gfx906* /opt/rocm/lib/rocblas/library/

# -----------------------------
# build llama.cpp for gfx906
# -----------------------------
WORKDIR /opt

RUN git clone https://github.com/ggerganov/llama.cpp.git

WORKDIR /opt/llama.cpp

RUN cmake -B build -S . \
    -DGGML_HIP=ON \
    -DGGML_HIPBLAS=ON \
    -DGPU_TARGETS=gfx906 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=/opt/rocm \
 && cmake --build build -j$(nproc)

WORKDIR /opt/llama.cpp/build/bin

EXPOSE 8080

ENTRYPOINT ["./llama-server"]

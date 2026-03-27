FROM spack/ubuntu-noble:develop

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/llvm.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble main" \
        > /etc/apt/sources.list.d/llvm.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        clang \
        lld \
        llvm \
    && rm -rf /var/lib/apt/lists/*

COPY spack.yaml /opt/spack-environment/spack.yaml

RUN spack compiler find

RUN --mount=type=secret,id=buildcache_token,required=false \
    TOKEN=$(cat /run/secrets/buildcache_token 2>/dev/null || true) \
    && if [ -n "$TOKEN" ]; then \
        spack mirror add \
            --oci-username token \
            --oci-password "$TOKEN" \
            buildcache \
            oci://ghcr.io/wdconinc/ubuntu-llvm-toolchain-questing/buildcache; \
    fi \
    && spack -e /opt/spack-environment install \
    && if [ -n "$TOKEN" ]; then \
        spack -e /opt/spack-environment buildcache push --unsigned --update-index buildcache || true \
        && spack mirror remove buildcache; \
    fi

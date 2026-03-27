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

RUN --mount=type=secret,id=buildcache_token \
    spack -e /opt/spack-environment install --no-check-signature \
    && TOKEN=$(cat /run/secrets/buildcache_token 2>/dev/null || true) \
    && if [ -n "$TOKEN" ]; then \
        cp /opt/spack-environment/spack.yaml /tmp/spack.yaml.bak \
        ; spack -e /opt/spack-environment mirror set \
            --oci-username token \
            --oci-password "$TOKEN" \
            buildcache \
        ; spack -e /opt/spack-environment buildcache push --unsigned --update-index buildcache || true \
        ; mv /tmp/spack.yaml.bak /opt/spack-environment/spack.yaml; \
    fi

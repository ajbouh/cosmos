# syntax=docker/dockerfile:1-labs

FROM busybox as busybox

# define a starting point "scratch" image that can run APEs
FROM scratch as cosmos-scratch
COPY --from=busybox /bin/uname /usr/bin/
ADD --chmod=0755 --checksum=sha256:349f3f511c4eb70c4db52e2fb99a41d9b208c83c3ec682c057ebaf1fe5f9857b https://cosmo.zip/pub/cosmos/v/3.1.3/bin/assimilate-x86_64.elf /usr/bin/
ADD --chmod=0755 --checksum=sha256:7b6f27e3997be53afc70717e0d7dea35eea799987224380bccc176b494996d0f https://cosmo.zip/pub/cosmos/v/3.1.3/bin/dash /bin/sh
RUN ["/usr/bin/assimilate-x86_64.elf", "-c", "/bin/sh"]
ADD --checksum=sha256:abf3b1bb7182935bf48d98dc143c51ee563d29a1fd2c3930ff5a8d8c8d823817 --chmod=0755 https://cosmo.zip/pub/cosmos/v/3.1.3/bin/ape-x86_64.elf /usr/bin/ape
ENV PATH=/bin:/usr/bin

# download and unpack all the cosmos binaries
FROM cosmos-scratch as unpack-cosmos
ADD --chmod=0755 --checksum=sha256:d9bf928f1aa32e3588087337cb04568b3284fc678b079612e7b74f72f01c0913 https://cosmo.zip/pub/cosmos/v/3.1.3/bin/unzip /usr/bin/
RUN ["/usr/bin/assimilate-x86_64.elf", "-c", "/usr/bin/unzip"]
ADD  --checksum=sha256:e280987f99f8c9802fa5564adbdc08ec7a8f8738c16a75cf74fb820cc1c14981 https://cosmo.zip/pub/cosmos/zip/cosmos-3.1.3.zip /dl/cosmos.zip

# list of binaries that must be assimilated and manifest for /bin as described in https://justine.lol/cosmos.txt (as of 2023-11-29)
WORKDIR /opt/cosmos
RUN unzip /dl/cosmos.zip
WORKDIR /opt/cosmos/bin
RUN /usr/bin/assimilate-x86_64.elf -c assimilate \
  && /usr/bin/assimilate-x86_64.elf -c dd \
  && /usr/bin/assimilate-x86_64.elf -c cp \
  && /usr/bin/assimilate-x86_64.elf -c mv \
  && /usr/bin/assimilate-x86_64.elf -c echo \
  && /usr/bin/assimilate-x86_64.elf -c uname \
  && /usr/bin/assimilate-x86_64.elf -c mkdir \
  && /usr/bin/assimilate-x86_64.elf -c chmod \
  && /usr/bin/assimilate-x86_64.elf -c gzip \
  && /usr/bin/assimilate-x86_64.elf -c printf \
  # assimilate these so the build works on github actions...
  && /usr/bin/assimilate-x86_64.elf -c rmdir \
  && /usr/bin/assimilate-x86_64.elf -c ln \
  && /usr/bin/assimilate-x86_64.elf -c tar \
  && /usr/bin/assimilate-x86_64.elf -c unzip
RUN ./mv '[' bash cat chgrp chmod chown cksum cp date df echo false grep kill ln ls mkdir mknod mktemp mv nice printenv pwd rm rmdir sed sleep stat sync touch true uname /bin/ \
  && /bin/mv * /usr/bin/
WORKDIR /
RUN rmdir /opt/cosmos/bin /opt/cosmos

ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh"]
CMD ["/bin/bash"]

# download and unpack the cosmo source code
FROM cosmos-scratch as unpack-cosmo
ADD --checksum=sha256:8d1058afcd6f32f5e7edb708c0a3014d544a4b17d35449be71fbfdd2a1eb39ba https://github.com/jart/cosmopolitan/releases/download/3.1.1/cosmopolitan-3.1.1.tar.gz /dl/
WORKDIR /opt/cosmo
COPY --from=unpack-cosmos /usr/bin/tar /usr/bin/gzip /usr/bin/
RUN /usr/bin/tar --strip-components=1 -xf /dl/cosmopolitan-3.1.1.tar.gz

# download and unpack the cosmocc toolchain
FROM cosmos-scratch as unpack-cosmocc
ADD --checksum=sha256:fa982741f52a2199194b9f06229729eb1eb220d065b0a65cca6dec3b36a9c7df https://github.com/jart/cosmopolitan/releases/download/3.1.1/cosmocc-3.1.1.zip /dl/
WORKDIR /opt/cosmocc
COPY --from=unpack-cosmos /usr/bin/unzip /usr/bin/
RUN /usr/bin/unzip /dl/cosmocc-3.1.1.zip

# an image that suppoers a single APE
FROM cosmos-scratch as ape
# can be /usr/bin/python /usr/bin/qjs /usr/bin/sqlite3 /usr/bin/lua
ARG COSMOS_EXE=/usr/bin/python
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
COPY --from=unpack-cosmos ${COSMOS_EXE} ${COSMOS_EXE}
ENV PATH=/bin:/usr/bin
ENV COSMOS_EXE="${COSMOS_EXE}"
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh"]
CMD "${COSMOS_EXE}"

# define the final image in as few layers as possible
FROM cosmos-scratch as cosmos
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
COPY --from=unpack-cosmos /bin /bin
COPY --from=unpack-cosmos /usr/bin /usr/bin
COPY --from=unpack-cosmo /opt/cosmo /opt/cosmo
COPY --from=unpack-cosmocc /opt/cosmocc /opt/cosmocc
ENV PATH=/bin:/usr/bin:/opt/cosmocc/bin
RUN /bin/ln -s /opt/cosmocc/bin/cosmocc /usr/bin/cc \
  && /bin/ln -s /opt/cosmocc/bin/cosmocc /usr/bin/gcc
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh"]
CMD ["/bin/bash"]

# FROM cosmos-scratch as python-pip-cli
# ARG COSMOS_EXE=/usr/bin/python
# ARG COSMOS_PIP_INSTALL="huggingface_hub[cli]"
# ARG COSMOS_PIP_BINSTUB="huggingface-cli"
# LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
# COPY --from=unpack-cosmos ${COSMOS_EXE} ${COSMOS_EXE}
# ENV PATH=/bin:/usr/bin
# ENV COSMOS_EXE="${COSMOS_EXE}"
# ENV COSMOS_PIP_BINSTUB="${COSMOS_PIP_BINSTUB}"
# RUN python -m pip install --user --no-cache-dir ${COSMOS_PIP_INSTALL}
# ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh"]
# CMD "${COSMOS_EXE}" "/.local/bin/${COSMOS_PIP_BINSTUB}"

# COPY --from=unpack-cosmos /bin/ /bin/
# COPY --from=unpack-cosmos /usr/bin/ /usr/bin/
# CMD /bin/bash

FROM cosmos-scratch as llamafile
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
ARG LLAMAFILE_URL
ARG LLAMAFILE_CHECKSUM
ADD --checksum=${LLAMAFILE_CHECKSUM} --chmod=0755 ${LLAMAFILE_URL} /usr/bin/llamafile
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh", "/usr/bin/llamafile"]

FROM cosmos-scratch as llamafile-gguf
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
ARG LLAMAFILE_VERSION=0.4
ARG LLAMAFILE_CHECKSUM=sha256:0751da4dacf8c71707ec57eb1f456dc4fc4959928ae7e25e3bbc505849227a9e
ARG LLAMAFILE_SERVER_CHECKSUM=sha256:af25718508cbc6af659366058abb9c106bbdac8220babd8a2e2176b07cfd2544
ADD --checksum=${LLAMAFILE_CHECKSUM} --chmod=0755 https://github.com/Mozilla-Ocho/llamafile/releases/download/${LLAMAFILE_VERSION}/llamafile-${LLAMAFILE_VERSION} /usr/bin/llamafile
ADD --checksum=${LLAMAFILE_SERVER_CHECKSUM} --chmod=0755 https://github.com/Mozilla-Ocho/llamafile/releases/download/${LLAMAFILE_VERSION}/llamafile-server-${LLAMAFILE_VERSION} /usr/bin/llamafile-server
ARG GGUF_URL
ARG GGUF_CHECKSUM
ADD --checksum=${GGUF_CHECKSUM} --chmod=0755 ${GGUF_URL} /model.gguf
EXPOSE 8080
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh", "/usr/bin/llamafile-server", "-m", "/model.gguf", "--port", "8080", "--host", "0.0.0.0", "--nobrowser"]

FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 as devel-llamafile
COPY --from=llamafile-gguf /usr/bin/llamafile /usr/bin/llamafile-server /usr/bin/
# HACK we need to assimilate so this can run on github actions...
COPY --from=unpack-cosmos /usr/bin/assimilate /usr/bin/
RUN /usr/bin/assimilate -c /usr/bin/llamafile
# HACK get llamafile to build stubs we can use at runtime. would be better to use a "only compile stubs" entrypoint
RUN (/usr/bin/llamafile -m /dev/null --n-gpu-layers 1 || true) \
  && [ -e /root/.cosmo ] && [ -e /root/.llamafile ]

FROM cosmos-scratch as llamafile-cuda-scratch
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
COPY --from=devel-llamafile /usr/local/cuda/targets/x86_64-linux/lib/libcublas.so.12 /usr/local/cuda/targets/x86_64-linux/lib/libcublasLt.so.12 /usr/local/cuda/targets/x86_64-linux/lib/
COPY --from=devel-llamafile /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=devel-llamafile /lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/
WORKDIR /root
COPY --from=devel-llamafile /root/.cosmo /root/.cosmo
COPY --from=devel-llamafile /root/.llamafile /root/.llamafile
ENV PATH=/bin:/usr/bin
ENV HOME=/root
ENV LD_LIBRARY_PATH=/usr/local/cuda/targets/x86_64-linux/lib:/lib:/lib64
# HACK things seem to fail if we have multiple CUDA devices. limit ourselves to one device for now to avoid errors like:
# >  CUDA error 2 at /root/.llamafile/ggml-cuda.cu:7864: out of memory
# >  current device: 4
ENV CUDA_VISIBLE_DEVICES=0

FROM llamafile-cuda-scratch as llamafile-cuda
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
ARG LLAMAFILE_URL
ARG LLAMAFILE_CHECKSUM
ADD --checksum=${LLAMAFILE_CHECKSUM} --chmod=0755 ${LLAMAFILE_URL} /usr/bin/llamafile
ARG LLAMAFILE_N_GPU_LAYERS=35
ENV LLAMAFILE_N_GPU_LAYERS=${LLAMAFILE_N_GPU_LAYERS}
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\" --n-gpu-layers $LLAMAFILE_N_GPU_LAYERS", "sh", "/usr/bin/llamafile"]

FROM llamafile-cuda-scratch as llamafile-gguf-cuda
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
COPY --from=llamafile-gguf /usr/bin/llamafile /usr/bin/llamafile-server /usr/bin/
ARG GGUF_URL
ARG GGUF_CHECKSUM
ADD --checksum=${GGUF_CHECKSUM} --chmod=0755 ${GGUF_URL} /model.gguf
ARG LLAMAFILE_N_GPU_LAYERS=35
ENV LLAMAFILE_N_GPU_LAYERS=${LLAMAFILE_N_GPU_LAYERS}
EXPOSE 8080
ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\" --n-gpu-layers $LLAMAFILE_N_GPU_LAYERS", "sh", "/usr/bin/llamafile-server", "-m", "/model.gguf", "--port", "8080", "--host", "0.0.0.0", "--nobrowser"]

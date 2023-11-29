# syntax=docker/dockerfile:1-labs

FROM busybox as busybox

# define a starting point "scratch" image that can run APEs
FROM scratch as cosmos-scratch
COPY --from=busybox /bin/uname /usr/bin/
ADD --chmod=0755 --checksum=sha256:349f3f511c4eb70c4db52e2fb99a41d9b208c83c3ec682c057ebaf1fe5f9857b https://cosmo.zip/pub/cosmos/bin/assimilate-x86_64.elf /usr/bin/
ADD --chmod=0755 --checksum=sha256:7b6f27e3997be53afc70717e0d7dea35eea799987224380bccc176b494996d0f https://cosmo.zip/pub/cosmos/bin/dash /bin/sh
RUN ["/usr/bin/assimilate-x86_64.elf", "-c", "/bin/sh"]
ADD --checksum=sha256:abf3b1bb7182935bf48d98dc143c51ee563d29a1fd2c3930ff5a8d8c8d823817 --chmod=0755 https://justine.lol/ape.elf /usr/bin/ape
ENV PATH=/bin:/usr/bin

# download and unpack all the cosmos binaries
FROM cosmos-scratch as unpack-cosmos
ADD --chmod=0755 --checksum=sha256:48e33306662ff052b21bb84e4b03779d94127727758cfc43d1551ea05d44ee3d https://cosmo.zip/pub/cosmos/bin/unzip /usr/bin/
RUN ["/usr/bin/assimilate-x86_64.elf", "-c", "/usr/bin/unzip"]
ADD  --checksum=sha256:241dc90f3e92b22c9e08cfb5f6df2e920da258e3c461d9677f267ab7a6dff2fd https://cosmo.zip/pub/cosmos/zip/cosmos.zip /dl/

# list of binaries that must be assimilated and manifest for /bin as described in https://justine.lol/cosmos.txt (as of 2023-11-29)
WORKDIR /opt/cosmos
RUN unzip /dl/cosmos.zip
WORKDIR /opt/cosmos/bin
RUN /usr/bin/assimilate-x86_64.elf -c dd \
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

# FROM cosmos-scratch as mistral-7b-instruct-v0.1-Q4_K_M-main
# LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos
# COPY --chmod=0755 mistral-7b-instruct-v0.1-Q4_K_M-main.llamafile /usr/bin/mistral-7b-instruct-v0.1-Q4_K_M-main.llamafile
# ENV PATH=/bin:/usr/bin
# ENTRYPOINT ["/bin/sh", "-c", "exec \"$@\"", "sh", "/usr/bin/mistral-7b-instruct-v0.1-Q4_K_M-main.llamafile"]

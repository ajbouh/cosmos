# syntax=docker/dockerfile:1-labs

FROM busybox as unpack-cosmos
ADD --checksum=sha256:ce256ededf106748a09f13bf47ace9ef0e6f115d963353d3d63c21302c5f28f4 https://github.com/jart/cosmopolitan/releases/download/3.0.1/cosmos-3.0.1.zip /dl/
WORKDIR /opt/cosmos
RUN ["/bin/unzip", "/dl/cosmos-3.0.1.zip"]
RUN ["/bin/cp", "bin/dash", "bin/sh"]

FROM busybox as unpack-cosmo
ADD --checksum=sha256:2872d2f06ef5fd13a206d3ba7a9ef29eb9bd8ebfe9600a35d5c55a88ffd112df https://github.com/jart/cosmopolitan/releases/download/3.0.1/cosmopolitan-3.0.1.tar.gz /dl/
ADD --checksum=sha256:e222b38b53b999e3310a2e172a75992a28b1594af5c1e954c913fc54405c1135 https://github.com/jart/cosmopolitan/releases/download/3.0.1/cosmocc-0.0.16.zip /dl/
WORKDIR /opt/cosmo
RUN ["/bin/tar", "-xf", "/dl/cosmopolitan-3.0.1.tar.gz", "--strip-components=1"]
RUN ["/bin/unzip", "/dl/cosmocc-0.0.16.zip"]
WORKDIR /usr/bin
RUN ["/bin/ln", "-s", "/opt/cosmo/bin/cosmocc", "cc"]
RUN ["/bin/ln", "-s", "/opt/cosmo/bin/cosmocc", "gcc"]

FROM busybox as busybox

# Create the final image from scratch
FROM scratch
# We need sh and uname for cosmos at runtime.
COPY --from=busybox /bin/uname /bin/
ADD --checksum=sha256:e67d07bb3010cad678c02fbc787c360340060467ebb39d681b58389df40fc904 --chmod=0755 https://justine.lol/dash /bin/sh
ADD --checksum=sha256:2789991dd41483961a753040ffc083c0c5ff24b84c09a02892e5c584a3f8effa --chmod=0755 https://justine.lol/ape.elf /usr/bin/ape

COPY --from=unpack-cosmo /opt/cosmo /opt/cosmo
COPY --from=unpack-cosmo /usr/bin/cc /usr/bin/gcc /usr/bin/
COPY --from=unpack-cosmos /opt/cosmos /opt/cosmos

ENV PATH=/bin:/usr/bin:/opt/cosmo/bin:/opt/cosmos/bin
# RUN ["/opt/cosmo/bin/cosmocc", "--update"]

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/opt/cosmos/bin/bash"]
LABEL org.opencontainers.image.source https://github.com/ajbouh/cosmos

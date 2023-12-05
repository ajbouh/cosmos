# A (mostly) pure cosmos container image

To try out a container built by this repo (without needing to do a git clone), you can:
```
docker run --rm -it ghcr.io/ajbouh/cosmos:3.1.3
docker run --rm -it ghcr.io/ajbouh/cosmos:python-cosmo-3.1.3
docker run --rm -it ghcr.io/ajbouh/cosmos:lua-cosmo-3.1.3
docker run --rm -it ghcr.io/ajbouh/cosmos:sqlite3-cosmo-3.1.3
docker run --rm -it ghcr.io/ajbouh/cosmos:qjs-cosmo-3.1.3
docker run --rm -it ghcr.io/ajbouh/cosmos:llava-v1.5-7b-q4_k-cosmo-3.1.3
docker run --rm -it ghcr.io/ajbouh/cosmos:airoboros-m-7b-3.1.2-dare-0.85.q4_k_m-cosmo-3.1.3
```

If you have a GPU and your docker daemon has been configured to make use of it, try one of these commands:
```
docker run --rm -it --gpus all ghcr.io/ajbouh/cosmos:llava-v1.5-7b-q4_k-cuda-12.1.1-cosmo-3.1.3
docker run --rm -it --gpus all ghcr.io/ajbouh/cosmos:airoboros-m-7b-3.1.2-dare-0.85.q4_k_m-cuda-12.1.1-cosmo-3.1.3
```

To build and run one of these, first clone the project and then try one of these docker commands:
```
docker compose run --build --rm -it cosmos
docker compose run --build --rm -it python
docker compose run --build --rm -it lua
docker compose run --build --rm -it sqlite3
docker compose run --build --rm -it qjs
docker compose run --build --service-ports --rm -it llava-v1.5-7b-q4_k-cuda
docker compose run --build --service-ports --rm -it llava-v1.5-7b-q4_k
docker compose run --build --service-ports --rm -it airoboros-m-7b-3.1.2-dare-0.85.q4_k_m-cuda
docker compose run --build --service-ports --rm -it airoboros-m-7b-3.1.2-dare-0.85.q4_k_m
```


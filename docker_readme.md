# Docker 設置指南

## 1. 建立 Docker Image

複製 `vtcs_toolchain_64bit.tar.gz`

```bash
docker build --platform linux/amd64 -t x86-compiler-env .
```

## 2. 建立 Volume

```bash
docker volume create my_kernel_disk
```

## 3. 產生 Container

```bash
docker run --rm -it --platform linux/amd64 --name my_build_env -v my_kernel_disk:/build -v ~/.ssh:/root/.ssh -v $(pwd):/work x86-compiler-env
```

## 4. 從另一個 Terminal 進入 Container

```bash
docker exec -it my_build_env /bin/bash
```

## 5. Build Kernel

```bash
cd /build/Kernel_v2.5-8/
```

## 6. Build Rootfs

```bash
cd /build/Buildroot_v2.5/
```

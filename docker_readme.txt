1. 建立 docker image
copy vtcs_toolchain_64bit.tar.gz

docker build --platform linux/amd64 -t x86-compiler-env .

2. 建 volume
docker volume create my_kernel_disk

3. 產生 container
docker run --rm -it --platform linux/amd64 --name my_build_env -v my_kernel_disk:/build -v $(pwd):/work x86-compiler-env

4. 從另一個 terminal 進入 container
docker exec -it my_build_env /bin/bash

5. build kernel
cd /build/Kernel_v2.5-8/

6. Build rootfs
cd /build/Buildroot_v2.5/

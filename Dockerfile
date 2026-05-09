# 指定使用 x86_64 架構的 Ubuntu
FROM --platform=linux/amd64 ubuntu:24.04

# 避免安裝過程中的互動式提問
ENV DEBIAN_FRONTEND=noninteractive

# 安裝基本編譯工具與 cross compiler 常見的相依套件
RUN apt-get update && apt-get install -y \
    build-essential \
    bc \
    bison \
    flex \
    file \
    wget \
    cpio \
    unzip \
    rsync \
    libssl-dev \
    make \
    cmake \
    libc6-dev-i386 \
    git \
    curl \
    vim \
    libncurses5-dev \
    libncursesw5-dev \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 設定工作目錄
WORKDIR /work

# (可選) 如果你的 Cross Compiler 是壓縮檔，可以在這裡解壓縮
COPY vtcs_toolchain_64bit.tar.gz /opt/
RUN tar -zxvf /opt/vtcs_toolchain_64bit.tar.gz -C /opt/


# 設定環境變數，讓系統找得到你的 Cross Compiler (請根據實際路徑修改)
ENV PATH="/opt/vtcs_toolchain/vienna/usr/bin/:${PATH}"

CMD ["/bin/bash"]

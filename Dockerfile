FROM debian:sid AS clang
#RUN apt-get update && apt-get install -y curl llvm-8 clang-8 vim git make lld-8
RUN apt-get update && apt-get install -y curl vim git make
RUN curl -LO https://github.com/WebAssembly/binaryen/releases/download/version_77/binaryen-version_77-x86-linux.tar.gz && tar xzvf binaryen-version_77-x86-linux.tar.gz --strip-components=1 -C /usr/local/bin/
RUN ln -s $(which llvm-ar-8) /usr/local/bin/wasm64-unknown-unknown-ar
RUN ln -s $(which llvm-ranlib-8) /usr/local/bin/wasm64-unknown-unknown-ranlib

WORKDIR /clang
COPY . .



FROM clang AS musl
RUN git clone -b musl-wasm-native https://github.com/tiborvass/musl /musl
WORKDIR /musl


FROM musl

RUN CFLAGS="-target wasm64-unknown-unknown" CC=clang-8 ./configure --disable-shared --target=wasm32-unknown-unknown && make install

RUN ln -s wasm-ld-8 /usr/bin/wasm-ld && echo '!<arch>' > /usr/lib/llvm-8/lib/clang/8.0.0/lib/libclang_rt.builtins-wasm64.a

WORKDIR /src
COPY main.c .
RUN clang-8 -o main.wasm --target=wasm64 --sysroot=/usr/local/musl  -lc  main.c -Xlinker "--entry=main" -Xlinker  "--allow-undefined"
RUN wasm-dis main.wasm | grep 'import'

FROM scratch as final
COPY --from=base /src/main.wasm /main.wasm



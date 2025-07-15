FROM vitasdk/vitasdk:latest

WORKDIR /src
COPY . /src

RUN chmod +x scripts/build_vpk.sh scripts/build_bootloader.sh

CMD ["./scripts/build_vpk.sh"]
FROM ubuntu:22.04

# maintainer 라벨은 Dockerfile2.txt에 있던 내용을 참고하여 추가했습니다.
LABEL maintainer='Anton Melekhin'

# DEBIAN_FRONTEND를 noninteractive로 설정하여 apt 설치 중 질문이 나타나지 않도록 합니다.
ENV DEBIAN_FRONTEND=noninteractive
# 이 컨테이너가 systemd를 사용함을 명시합니다.
ENV container=docker

# 필요한 의존성 및 systemd를 설치합니다.
# findutils, iproute2, sudo는 systemd와 컨테이너 관리에 유용할 수 있습니다.
RUN apt update && \
    apt install -y software-properties-common wget curl git openssh-client tmate python3 \
                       systemd dbus iproute2 sudo && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# systemd가 컨테이너 환경에서 불필요한 서비스들을 시작하지 않도록 정리합니다.
# 이 명령은 systemd의 부팅 시간을 단축하고 컨테이너를 가볍게 유지하는 데 도움을 줍니다.
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -print0 | xargs -0 rm -vf || true

# 더미 index 페이지 생성 (기존 기능 유지)
RUN mkdir -p /app && echo "Tmate Session Running..." > /app/index.html
WORKDIR /app

# Expose ports (기존 기능 유지)
EXPOSE 6080
EXPOSE 19132/udp

# cgroup 볼륨 마운트: systemd가 제대로 작동하려면 필요합니다.
VOLUME [ "/sys/fs/cgroup" ]

# --- systemd 서비스 유닛 정의 ---

# 1. Dummy Python Web Server 서비스 유닛
RUN echo "[Unit]\n\
Description=Dummy Python Web Server\n\
After=network.target\n\n\
[Service]\n\
ExecStart=/usr/bin/python3 -m http.server 6080\n\
WorkingDirectory=/app\n\
Restart=on-failure\n\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/dummy-web.service

# 2. Tmate Session 서비스 유닛
RUN echo "[Unit]\n\
Description=Tmate Session Service\n\
After=network.target\n\n\
[Service]\n\
ExecStart=/usr/bin/tmate -F\n\
Restart=on-failure\n\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/tmate.service

# 정의된 systemd 서비스를 활성화합니다. (컨테이너 시작 시 자동 실행)
RUN systemctl enable dummy-web.service \
    && systemctl enable tmate.service

# 컨테이너의 진입점을 systemd로 설정하여 PID 1번 프로세스가 systemd가 되도록 합니다.
CMD ["/lib/systemd/systemd"]

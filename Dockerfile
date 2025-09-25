FROM ubuntu:24.04

LABEL maintainer='Anton Melekhin'
ENV container=docker \
    DEBIAN_FRONTEND=noninteractive

# 모든 필요한 패키지 설치
RUN apt update && \
    apt install -y software-properties-common wget curl git openssh-client tmate python3 \
                       findutils iproute2 python3-apt sudo systemd && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# systemd 관련 파일 정리 (도커 환경에 맞게)
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -print0 | xargs -0 rm -vf

# 더미 index 페이지 생성
RUN mkdir -p /app && echo "Tmate Session Running..." > /app/index.html
WORKDIR /app

# tmate 및 Python 웹 서버를 위한 systemd 서비스 유닛 생성
# python3 웹 서버 서비스 유닛
RUN echo "[Unit]\n\
Description=Dummy Python Web Server\n\
After=network.target\n\n\
[Service]\n\
ExecStart=/usr/bin/python3 -m http.server 6080\n\
WorkingDirectory=/app\n\
Restart=on-failure\n\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/dummy-web.service

# tmate 서비스 유닛
RUN echo "[Unit]\n\
Description=Tmate Session Service\n\
After=network.target\n\n\
[Service]\n\
ExecStart=/usr/bin/tmate -F\n\
Restart=on-failure\n\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/tmate.service

# Expose ports
EXPOSE 6080
EXPOSE 19132/udp

# cgroup 볼륨 마운트 (systemd를 위해 필요)
VOLUME [ "/sys/fs/cgroup" ]

# systemd 서비스 활성화
# ENTRYPOINT가 systemd를 실행하므로, systemd가 서비스들을 관리하도록 enable 합니다.
# 실제 실행은 systemd의 start 명령으로 이루어집니다.
CMD ["/lib/systemd/systemd", "multi-user.target"]
# systemd를 시작하고, 위에서 정의한 서비스들을 활성화합니다.
RUN systemctl enable dummy-web.service \
    && systemctl enable tmate.service

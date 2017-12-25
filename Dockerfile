FROM reg.cctv.cn/devops/ops:base

COPY docker/ops_platform.conf /etc/nginx/conf.d/
COPY docker/ops_platform.ini /etc/supervisor.d/

#COPY docker/start_webhook.py /opt/
#COPY docker/restart.sh /opt/

COPY docker/docker-entrypoint.sh /
#RUN mkdir -p /src
#RUN mkdir -p /opt/ops_platform #&& mkdir -p /opt/log/supervisor \
#    && git clone -b python3 git@git.cctv.cn:OPS/Ops_Platform.git /opt/ops_platform \
#    && git config --global user.email "zhangkai@cctv.cn" \
#    && git config --global user.name "ops"

#VOLUME ["/data"]
COPY . /opt/ops_platform
#RUN mkdir /opt/ops_platform
#注意安装pip
RUN mkdir -p /opt/log/supervisor/ && pip3 install -r /opt/ops_platform/requirements.txt
WORKDIR /opt/ops_platform

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]

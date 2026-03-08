# 使用你指定的华为云Alpine镜像（阿里云环境可稳定拉取）
FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/alpine:3.18

# 替换为阿里云Alpine软件源（内网安装JRE，速度快、无网络限制）
# 安装OpenJDK 17 JRE + 设置上海时区 + 清理冗余缓存（瘦身关键）
RUN echo "https://mirrors.aliyun.com/alpine/v3.18/main/" > /etc/apk/repositories \
    && echo "https://mirrors.aliyun.com/alpine/v3.18/community/" >> /etc/apk/repositories \
    && apk add --no-cache openjdk17-jre-headless tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo Asia/Shanghai > /etc/timezone \
    && rm -rf /var/cache/apk/* /tmp/*

# 工作目录
WORKDIR /app

# 复制你的jar包到镜像（确保app.jar和Dockerfile在同一目录）
COPY app.jar /app/app.jar

# 启动命令（简洁稳定，适配所有Java 17 Jar应用）
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
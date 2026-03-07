# 原写法
# FROM openjdk:17-jre-slim

# 新写法（使用阿里云的镜像）
FROM openjdk:17-jdk-slim

WORKDIR /app
COPY app.jar /app/app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
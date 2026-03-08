pipeline {
    agent any
    environment {
        // ========== 仅需替换这3处！==========
        // 先读取version文件的版本号（核心修改）
        APP_VERSION = readFile('VERSION').trim()  // 读取文件并去除首尾空格/换行
        ACR_IMAGE = "registry.cn-hangzhou.aliyuncs.com/laoli_k8s/my-app:${APP_VERSION}"
        ACR_CRED_ID = "aliyun-acr-cred"  // Jenkins中ACR凭证ID
        JUMP_HOST = "aliyun_ecs"         // Jenkins中配置的跳板机SSH名称
        // Jar包路径（Jenkins打包后生成的路径，默认target/*.jar）
        JAR_PATH = "target/*.jar"
        // ECS目标目录（改为你的/root/my-app）
        ECS_APP_DIR = "/root/my-app"
    }
    stages {
        // 1. Jenkins拉取GitHub源码 + 本地Maven打包Jar
        stage('Jenkins Build Jar') {
            steps {
                echo "📥 Jenkins拉取GitHub源码..."
                checkout scm  // 拉取GitHub源码（已配凭证，无需额外操作）

                echo "🔨 Jenkins本地Maven打包Jar..."
                sh 'mvn clean package -DskipTests'  // Jenkins本地打包
                sh "ls -l ${JAR_PATH}"  // 验证Jar包生成
            }
        }

        // 2. 仅传Jar包+Dockerfile+deploy.yaml到ECS的/root/my-app目录
        stage('Upload Jar/Dockerfile to ECS') {
            steps {
                echo "📤 上传Jar包/Dockerfile/deploy.yaml到ECS的${ECS_APP_DIR}目录..."
                sshPublisher(
                    publishers: [
                        sshPublisherDesc(
                            configName: "${JUMP_HOST}",
                            transfers: [
                                // 上传Jar包到ECS的/root/my-app目录
                                sshTransfer(
                                    sourceFiles: "${JAR_PATH}",
                                    remoteDirectory: '',  // 不填，默认使用Jenkins中配置的remote Directory
                                    flatten: true,  // 直接放在目标目录，不创建target子目录
                                    cleanRemote: false
                                ),
                                // 上传Dockerfile到ECS的/root/my-app目录
                                sshTransfer(
                                    sourceFiles: 'Dockerfile',
                                    remoteDirectory: '',
                                    flatten: true
                                ),
                                // 上传deploy.yaml到ECS的/root/my-app目录
                                sshTransfer(
                                    sourceFiles: 'deploy.yaml',
                                    remoteDirectory: '',
                                    flatten: true
                                )
                            ]
                        )
                    ]
                )
            }
        }

        // 3. ECS（/root/my-app）构建Docker镜像 + 推送阿里云ACR
        stage('ECS Build & Push Image') {
            steps {
                echo "🔨 ECS在${ECS_APP_DIR}目录构建镜像并推送ACR..."
                // 安全获取ACR凭证（日志脱敏）
                withCredentials([usernamePassword(
                    credentialsId: "${ACR_CRED_ID}",
                    usernameVariable: 'ACR_USER',
                    passwordVariable: 'ACR_PWD'
                )]) {
                    // ECS上执行：构建镜像 → 推送ACR
                    sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: "${JUMP_HOST}",
                                transfers: [
                                    sshTransfer(
                                        sourceFiles: '', // 不传输文件，只执行命令
                                        remoteDirectory: '',
                                        execCommand: """
                                            # 显式定义所有需要的环境变量
                                            export ECS_APP_DIR="${ECS_APP_DIR}"
                                            export ACR_IMAGE="${ACR_IMAGE}"
                                            export ACR_USER="${ACR_USER}"
                                            export ACR_PWD="${ACR_PWD}"

                                            # 进入ECS的目标目录
                                            cd \$ECS_APP_DIR || exit 1
                                            # 先清理旧的app.jar，避免重命名警告
                                            rm -f app.jar
                                            # 重命名Jar包为app.jar（避免名称不一致）
                                            mv *.jar app.jar
                                            # 登录ACR + 构建镜像 + 推送
                                            echo "\$ACR_PWD" | docker login registry.cn-hangzhou.aliyuncs.com -u "\$ACR_USER" --password-stdin
                                            echo "开始构建镜像\$ACR_IMAGE"
                                            docker build -t \$ACR_IMAGE .
                                            docker push \$ACR_IMAGE
                                            # 清理本地镜像（可选）
                                            # docker rmi \$ACR_IMAGE
                                            docker logout registry.cn-hangzhou.aliyuncs.com
                                        """
                                    )
                                ],
                                verbose: true
                            )
                        ]
                    )
                }
            }
        }

        // 4. ECS（/root/my-app）部署镜像到K8s集群
        stage('ECS Deploy to K8s') {
            steps {
                echo "🚀 ECS在${ECS_APP_DIR}目录部署镜像到K8s..."
                sshPublisher(
                    publishers: [
                        sshPublisherDesc(
                            configName: "${JUMP_HOST}",
                            transfers: [
                                sshTransfer(
                                    sourceFiles: '', // 不传输文件，只执行命令
                                    remoteDirectory: '',
                                    execCommand: """
                                        # 1. 显式定义ECS需要的环境变量（从Jenkins传递值）
                                        export ECS_APP_DIR="${ECS_APP_DIR}"
                                        export APP_VERSION="${APP_VERSION}"
            
                                        # 2. 进入目标目录，失败则退出
                                        cd \$ECS_APP_DIR || exit 1
            
                                        # 3. 替换deploy.yaml中的${APP_VERSION}占位符（修正转义）
                                        sed -i "s/APP_VERSION/\$APP_VERSION/g" deploy.yaml
            
                                        # 4. 部署到K8s并查看状态
                                        kubectl apply -f deploy.yaml
                                        echo '✅ 部署完成，查看状态：'
                                        # 增加容错，避免grep不到内容导致脚本失败
                                        kubectl get pods -n default | grep github-app || echo '⚠️ 未找到github-app相关Pod'
                                        kubectl get svc -n default | grep github-app-service || echo '⚠️ 未找到github-app-service相关Service'
                                    """
                                )
                            ],verbose: true
                        )
                    ]
                )
            }
        }
    }
    post {
        always {
            echo "🎉 全流程执行完成！所有文件均在ECS的${ECS_APP_DIR}目录下"
        }
    }
}
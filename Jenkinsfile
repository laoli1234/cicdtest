pipeline {
    agent any
    stages {
        // 1. 拉取GitHub代码
        stage('拉取代码') {
            steps {
                git(
                    url: 'https://github.com/laoli1234/cicdtest.git',
                    credentialsId: 'github_token',
                    branch: 'master'
                )
            }
        }

        // 2. 打包项目（Java项目保留）
        stage('打包代码') {
            steps {
                sh 'mvn clean package -DskipTests'
                sh 'cp target/*.jar app.jar' // 统一jar包名
            }
        }

        // 3. 上传文件到ECS的/root/my-app目录（新版正确语法）
        stage('上传到ECS') {
            steps {
                publishOverSsh(
                    continueOnError: false,
                    failOnError: true,
                    publishers: [
                        [
                            configName: 'aliyun_ecs', // 和你SSH配置的名称一致
                            transfers: [
                                [
                                    sourceFiles: 'app.jar',
                                    remoteDirectory: '', // 空=使用SSH配置里的/root/my-app
                                    flatten: true,
                                    cleanRemote: false
                                ],
                                [
                                    sourceFiles: 'Dockerfile',
                                    remoteDirectory: '',
                                    flatten: true,
                                    cleanRemote: false
                                ]
                            ],
                            verbose: true
                        ]
                    ]
                )
            }
        }

        // 4. 在ECS的/root/my-app目录部署Docker（无语法错误）
        stage('ECS部署Docker') {
            steps {
                publishOverSsh(
                    continueOnError: false,
                    failOnError: true,
                    publishers: [
                        [
                            configName: 'aliyun_ecs',
                            exec: [
                                command: '''
                                    # 进入配置好的/root/my-app目录
                                    cd /root/my-app
                                    # 停止并删除旧容器（失败不报错）
                                    docker stop my-app || true
                                    docker rm my-app || true
                                    # 构建镜像并启动新容器
                                    docker build -t my-app:latest .
                                    docker run -d -p 80:8080 --name my-app my-app:latest
                                ''',
                                escape: false, // 避免命令特殊符号被转义
                                label: '执行Docker部署命令'
                            ],
                            transfers: [], // 无文件传输，空数组
                            verbose: true
                        ]
                    ]
                )
            }
        }
    }
}
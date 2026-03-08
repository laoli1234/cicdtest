pipeline {
    agent any
    stages {
        // 1. 从 GitHub 拉取代码
        stage('拉取代码') {
            steps {
                git(
                    url: 'https://github.com/laoli1234/cicdtest.git',
                    credentialsId: 'github_token',
                    branch: 'master'
                )
            }
        }

        // 2. 打包项目（Java 项目需要）
        stage('打包代码') {
            steps {
                sh 'mvn clean package -DskipTests'
                sh 'cp target/*.jar app.jar'
            }
        }

        // 3. 上传文件到 ECS（保持你原来的写法）
        stage('上传到ECS') {
            steps {
                sshPublisher(publishers: [
                    sshPublisherDesc(
                        configName: 'aliyun_ecs',
                        transfers: [
                            sshTransfer(sourceFiles: 'app.jar', remoteDirectory: '', flatten: true),
                            sshTransfer(sourceFiles: 'Dockerfile', remoteDirectory: '', flatten: true)
                        ],
                        verbose: true
                    )
                ])
            }
        }

        // 4. 在 ECS 上部署（只改这里的 exec 语法）
        stage('ECS部署Docker') {
            steps {
                sshPublisher(publishers: [
                    sshPublisherDesc(
                        configName: 'aliyun_ecs',
                        transfers: [
                            sshTransfer(
                                sourceFiles: '', // 不传输文件，只执行命令
                                remoteDirectory: '',
                                execCommand: '''
                                    cd /root/my-app
                                    docker stop my-app || true
                                    docker rm my-app || true
                                    docker build -t my-app:latest .
                                    docker run -d -p 80:8080 --name my-app my-app:latest
                                '''
                            )
                        ],
                        verbose: true
                    )
                ])
            }
        }
    }
}
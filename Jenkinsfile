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

        // 2. 打包项目（Java 项目需要，其他项目可删除）
        stage('打包代码') {
            steps {
                sh 'mvn clean package -DskipTests'
                sh 'cp target/*.jar app.jar' // 统一 jar 包名
            }
        }

        // 3. 上传文件到 ECS
        stage('上传到ECS') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(
                    configName: 'aliyun_ecs', // 这里要和刚才配置的 Name 一致
                    transfers: [
                        sshTransfer(sourceFiles: 'app.jar', remoteDirectory: '', flatten: true),
                        sshTransfer(sourceFiles: 'Dockerfile', remoteDirectory: '', flatten: true)
                    ],
                    verbose: true
                )])
            }
        }

        // 4. 在 ECS 上构建并启动 Docker 容器
        stage('ECS部署Docker') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(
                    configName: 'aliyun_ecs',
                    execCommand: '''
                        cd /root/my-app
                        docker stop my-app || true
                        docker rm my-app || true
                        docker build -t my-app:latest .
                        docker run -d -p 80:8080 --name my-app my-app:latest
                    ''',
                    verbose: true
                )])
            }
        }
    }
}
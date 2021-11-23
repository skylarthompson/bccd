pipeline {
    agent any
    stages {
        stage('target/debootstrap.tar.bz2') {
            steps {
                sh 'make target/debootstrap.tar.bz2'
                archiveArtifacts artifacts: 'target/debootstrap.tar.bz2', fingerprint: true
            }
            post {
                cleanup {
                    sh 'rm -rf debootstrap'
                }
            }
        }
    }
}

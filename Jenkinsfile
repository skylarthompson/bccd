pipeline {
    agent any
    stages {
        stage('target/debootstrap.tar.bz2') {
            steps {
                sh 'make target/debootstrap.tar.bz2'
                stash includes: 'target/debootstrap.tar.bz2'
            }
            post {
                cleanup {
                    sh 'rm -rf debootstrap'
                }
            }
        }
    }
}

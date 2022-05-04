pipeline {
    agent any
    stages {
        stage('target/debootstrap.tar.bz2') {
            steps {
                sh 'make target/debootstrap.tar.bz2'
                stash includes: 'target/debootstrap.tar.bz2', name: 'debootstrap.tar.bz2'
            }
            post {
                cleanup {
                    sh 'umount debootstrap/dev || exit 0'
                    sh 'umount debootstrap/sys || exit 0'
                    sh 'rm -rf debootstrap'
                }
            }
        }
        stage('target/bccd.noarch.deb') {
            steps {
                sh 'make target/bccd.noarch.deb'
                stash includes: 'target/bccd.noarch.deb', name: 'bccd.noarch.deb'
            }
        }
        stage('target/debootstrap-bccd.tar.bz2') {
            steps {
                sh 'make target/debootstrap-bccd.tar.bz2'
                stash includes: 'target/debootstrap-bccd.tar.bz2', name: 'debootstrap-bccd.tar.bz2'
            }
        }
    }
}

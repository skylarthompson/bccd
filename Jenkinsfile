pipeline {
    agent any
    stages {
        stage('target/debootstrap.tar.bz2') {
            steps {
                sh 'vagrant up'
                sh 'echo make -C /vagrant target/debootstrap.tar.bz2|vagrant ssh'
                stash includes: 'target/debootstrap.tar.bz2', name: 'debootstrap.tar.bz2'
            }
            post {
                cleanup {
                    sh 'vagrant destroy'
                }
            }
        }
        stage('target/bccd.noarch.deb') {
            steps {
                sh 'vagrant up'
                sh 'echo make -C /vagrant target/bccd.noarch.deb|vagrant ssh'
                stash includes: 'target/bccd.noarch.deb', name: 'bccd.noarch.deb'
            }
        }
        stage('target/debootstrap-bccd.tar.bz2') {
            steps {
                sh 'vagrant up'
                sh 'echo make -C /vagrant target/debootstrap-bccd.tar.bz2|vagrant ssh'
                stash includes: 'target/debootstrap-bccd.tar.bz2', name: 'debootstrap-bccd.tar.bz2'
            }
            post {
                cleanup {
                    sh 'vagrant destroy'
                }
            }
        }
    }
}

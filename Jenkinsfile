pipeline {
    agent any
    stages{
        stage('debootstrap') {
            steps {
                sh 'make debootstrap'
                archiveArtifacts artifacts: 'target/debootstrap.tar.bz2', fingerprint: true
            }
        }
    }
}

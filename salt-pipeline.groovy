pipeline {
  agent {
    label "saltmaster"
  }

  stages {
    stage('compare code in blob vs latest implemented via md5'){
      steps {
        echo "Running ${env.BUILD_ID} on ${env.JENKINS_URL}"
        sh '''
            blobxfer download --storage-account $STORAGE_ACCOUNT --storage-account-key "$STORAGE_ACCOUNT_KEY" --remote-path $REMOTE_PATH/latest_artifacts_${fork}.tgz --local-path ./salt_artifacts
            CURRENT_MD5=`/bin/md5sum ./salt_artifacts/latest_artifacts_${fork}.tgz |awk {'print $1'}`
            if [ -f "./salt_artifacts/.latest_md5" ]
            then
            LATEST_MD5=`cat ./salt_artifacts/.latest_md5`
            else
            LATEST_MD5=000
            fi

            if [ ${CURRENT_MD5} != ${LATEST_MD5} ]
            then
            echo "Deploying now... "
            else
            curl --request POST -u clintadmin:$clintadmin "http://10.27.234.40:8080/job/Salt-Deployment/lastBuild/stop?token=insecure"
            sleep 60s
            exit 1
            fi
        '''
      }
    }
    stage('Push code to saltmaster'){
      steps {
        echo "Running ${env.BUILD_ID} on ${env.JENKINS_URL}"
        sh '''
            rm -rf /srv.bak && systemctl stop salt-master && mv /srv /srv.bak
            cp -f ./salt_artifacts/latest_artifacts_${fork}.tgz /tmp/
            tar xzfp /tmp/latest_artifacts_${fork}.tgz -C / && mv /dist /srv && systemctl start salt-master

            /bin/md5sum ./salt_artifacts/latest_artifacts_${fork}.tgz |awk {'print $1'} > ./salt_artifacts/.latest_md5
        '''
      }
    }
    stage('Push code via highstate'){
      steps {
        echo "Running ${env.BUILD_ID} on ${env.JENKINS_URL}"
        sh '''
            sleep 120s
            set +e
            salt '*' state.highstate --state-output=changes || true
        '''
      }
    }
  }
}

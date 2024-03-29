# aws-cli
Docker container to easily send AWS CLI commands to Localstack Pro.

The following assumes you have a licensed copy of Localstack Pro.

In your `.env-localstack` file

```sh
LOCALSTACK_API_KEY=xxxxxxxx
...
```

In your `docker-compose.yml` file:

```yml
services:
  localstack:
    ...
    env-file: ./.env-localstack
    networks:
      my_network:
        ipv4_address: 10.5.0.2

  ...

  aws-setup:
    build:
      context: ../aws-cli
    image: po/aws-cli
    container_name: aws-setup
    environment:
      - AWS_ACCESS_KEY_ID=dummyaccess
      - AWS_SECRET_ACCESS_KEY=dummysecret
      - AWS_DEFAULT_REGION=us-east-1
    entrypoint: /bin/sh -c
    command: >
      "
        aws --version

        echo Creating Kinesis Stream
        aws --no-verify-ssl \
          kinesis create-stream \
          --stream-name my_stream \
          --shard-count 1 \
          2>&1 | grep -v InsecureRequestWarning

        echo Create SQS Queue
        aws --no-verify-ssl \
          sqs create-queue \
          --queue-name my_queue \
          2>&1 | grep -v InsecureRequestWarning

        echo Creating User Pool
        POOL_INFO=$$(aws --no-verify-ssl \
          cognito-idp create-user-pool \
          --pool-name my_pool \
          2>&1 | grep -v InsecureRequestWarning)
        POOL_ID=$$(echo $$POOL_INFO | jq -rc .UserPool.Id)
        echo $$POOL_INFO

        echo Creating User Pool Client
        POOL_CLIENT_INFO=$$(aws --no-verify-ssl \
          cognito-idp create-user-pool-client \
          --user-pool-id $$POOL_ID \
          --client-name my_user_pool_client \
          2>&1 | grep -v InsecureRequestWarning)
        echo $$POOL_CLIENT_INFO

        echo Creating User
        POOL_USER_INFO=$$(aws --no-verify-ssl \
          cognito-idp admin-create-user \
          --user-pool-id $$POOL_ID \
          --username miles.elam@productops.com \
          --user-attributes=Name=email,Value=miles.elam@productops.com \
          --message-action SUPPRESS \
          2>&1 | grep -v InsecureRequestWarning)
        POOL_USER_ID=$$(echo $$POOL_USER_INFO | jq -rc .User.Username)
        echo $$POOL_USER_INFO

        echo Confirming User
        aws --no-verify-ssl \
          cognito-idp admin-confirm-sign-up \
          --user-pool-id $$POOL_ID \
          --username $$POOL_USER_ID \
          2>&1 | grep -v InsecureRequestWarning

        echo Setting User Password
        aws --no-verify-ssl \
          cognito-idp admin-set-user-password \
          --user-pool-id $$POOL_ID \
          --username $$POOL_USER_ID \
          --password insecure \
          --permanent \
          2>&1 | grep -v InsecureRequestWarning

        echo Done!
      "
    networks:
      my_network:
    dns: 10.5.0.2
    depends_on:
      localstack:

networks:
  my_network:
    driver: bridge
    ipam:
      config:
        - subnet: 10.5.0.0/16
          gateway: 10.5.0.1

```
Note: --no-verify-ssl is mandatory.

Note: `2>&1 | grep -v InsecureRequestWarning` suppresses the warning generated by
`--no-verify-ssl`, which can make viewing logs a lot more tedious.

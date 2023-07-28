# Test Kitchen with Docker and CloudFormation

This project demonstrates how to use Test Kitchen with Docker and AWS CloudFormation. It includes a Makefile for easy command handling and a Dockerfile to create a standardized testing environment.

## Prerequisites

1. AWS Access

## Required Environment Variables

Make sure to set these environment variables before running the tests:

- `USER`: Your username
- `OBSERVE_CUSTOMER`: The Observe customer
- `OBSERVE_TOKEN`: The Observe token
- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `AWS_SESSION_TOKEN`: Your AWS session token (if required)
- `AWS_REGION`: Your preferred AWS region (default: us-east-1)

## Developing

```
gem install pry
```

Update rspec code to include `binding.pry`

Instead of 
`rspec -c -f documentation --default-path '/workdir'  -P 'test/integration/base/verify/collection_spec.rb'` 
to run the rspec run
`rspec -rpry -c -f documentation --default-path '/workdir' -P 'test/integration/base/verify/collection_spec.rb'`

## Docker

### Prerequisites

1. Docker installed

### Testing

1. Run the tests within a docker container by running `make docker/test`.
2. To clean up the resources created during the test, run `make docker/test/clean`
3. To clean up the resources including the docker image / container run `make docker/clean`

## Manual

### Prerequisites

1. Ensure the dependencies within the `./validate_deps.sh` script are installed by running `./validate_deps.sh`.
2. Install the gems listed within the Gemfile via `bundler install`.
3. Configure AWS CLI with your credentials. You can check this by running `aws sts get-caller-identity`.

### Testing

1. Run `make test` to validate dependencies, create the kitchen environment and run the verifier.
2. To clean up the resources created during the test, run `make test/clean`.

## Test Kitchen Configuration

The Test Kitchen configuration is defined in the `kitchen.yml` file. By default, it uses AWS CloudFormation as the provider, but it can be changed to Terraform by setting the `PROVIDER` environment variable to `terraform`.

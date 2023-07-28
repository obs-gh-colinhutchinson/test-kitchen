require 'awspec'
require 'aws-sdk'
require 'aws-sdk-cloudwatchlogs'

provider = ENV['PROVIDER']
region = ENV['AWS_REGION']
user = ENV.fetch('USER', 'observe')

Aws.config[:region] = region

RSpec.configure do |config|
  config.before(:each) do
    sts = Aws::STS::Client.new
    account_id = sts.get_caller_identity.account

    # Specify the AWS Account ID
    ENV['AWS_ACCOUNT_ID'] = account_id
  end
end

describe lambda("spec-test-#{provider}-#{user}") do
    it { should exist }
    its(:timeout) { should eq 120 }
    its(:runtime) { should eq 'go1.x' }
    its(:handler) { should eq 'main' }
end

# Get all S3 buckets
s3 = Aws::S3::Client.new
s3_bucket_found = false
s3.list_buckets.buckets.each do |bucket|
  # Filter out the ones that match your prefix
  if bucket.name.start_with?("spec-test-#{provider}-#{user}")
    s3_bucket_found = true
    describe s3_bucket(bucket.name) do
      it { should exist }
    end
  end
end

describe 's3 bucket' do
  it 'has at least s3 bucket' do
    expect(s3_bucket_found).to be true
  end
end

# Get all Firehose delivery streams
firehose = Aws::Firehose::Client.new
firehose_found = true
firehose.list_delivery_streams.delivery_stream_names.each do |stream|
  # Filter out the ones that match your prefix
  if stream.start_with?("spec-test-#{provider}-#{user}")
    firehose_found = true
    describe firehose(stream) do
      it { should exist }
    end
  end
end

describe 'Firehose group' do
  it 'has at least one firehose' do
    expect(firehose_found).to be true
  end
end

# Get all CloudWatch log groups
logs = Aws::CloudWatchLogs::Client.new
cloudwatch_group_found = false
logs.describe_log_groups.log_groups.each do |log_group|
  # Filter out the ones that match your prefix
  if log_group.log_group_name.start_with?("/aws/lambda/spec-test-#{provider}-#{user}")
    cloudwatch_group_found = true
    describe cloudwatch_logs(log_group.log_group_name) do
      it { should exist }
      subscription_filters = logs.describe_subscription_filters({log_group_name: log_group.log_group_name}).subscription_filters
      it 'has a subscription filter' do
        expect(subscription_filters).not_to be_empty
      end
    end
  end
end

describe 'Cloudwatch group' do
  it 'has at least one cloudwatch group' do
    expect(cloudwatch_group_found).to be true
  end
end

# Get all EventBridge rules
events = Aws::CloudWatchEvents::Client.new
eventbridge_rule_found = false
events.list_rules.rules.each do |rule|
  # Filter out the ones that match your prefix
  if rule.name.start_with?("spec-test-#{provider}")
    eventbridge_rule_found = true

    describe 'EventBridge Rule' do
      it 'exists' do
        expect(rule).not_to be_nil
      end

      it 'is enabled' do
        expect(rule.state).to eq 'ENABLED'
      end

      # Check if rule targets the correct Lambda function and has correct inputs
      targets = events.list_targets_by_rule({rule: rule.name}).targets
      targets.each do |target|
        if target.arn.include?("function:spec-test-#{provider}-#{user}")
          it 'has correct input' do
            input_json = JSON.parse(target.input)
            expected_include_array = ["apigateway:Get*", "autoscaling:Describe*", "cloudformation:Describe*", "cloudformation:List*", "cloudfront:List*", "dynamodb:Describe*", "dynamodb:List*", "ec2:Describe*", "ecs:Describe*", "ecs:List*", "eks:Describe*", "eks:List*", "elasticache:Describe*", "elasticbeanstalk:Describe*", "elasticfilesystem:Describe*", "elasticloadbalancing:Describe*", "elasticmapreduce:Describe*", "elasticmapreduce:List*", "events:List*", "firehose:Describe*", "firehose:List*", "iam:Get*", "iam:List*", "kinesis:Describe*", "kinesis:List*", "kms:Describe*", "kms:List*", "lambda:List*", "logs:Describe*", "organizations:Describe*", "organizations:List*", "rds:Describe*", "redshift:Describe*", "route53:List*", "s3:GetBucket*", "s3:List*", "secretsmanager:List*", "sns:Get*", "sns:List*", "sqs:Get*", "sqs:List*", "synthetics:Describe*", "synthetics:List*"]
            expected_include_array.each do |expected_element|
              expect(input_json['snapshot']['include']).to include(expected_element)
            end
          end
        end
      end
    end
  end
end

describe 'EventBridge rules' do
  it 'has at least one matching rule' do
    expect(eventbridge_rule_found).to be true
  end
end

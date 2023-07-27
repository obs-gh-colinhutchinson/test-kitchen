require 'awspec'
require 'aws-sdk'
require 'aws-sdk-cloudwatchlogs'

provider = ENV['PROVIDER']
region = ENV['AWS_REGION']
user = ENV.fetch('USER', 'observe')

if provider == 'cloudformation'
    # Instantiate a new AWS SDK client for CloudFormation
    cf = Aws::CloudFormation::Client.new(region: region)

    # Get the details of the stack
    stack = cf.describe_stacks(stack_name: "spec-test-cf-#{user}").stacks.first

    # Extract the ARN's from the stack output
    iam_role_arn = stack.outputs.find { |output| output.output_key == 'CloudWatchLogsRole' }.output_value
    firehose_arn = stack.outputs.find { |output| output.output_key == 'FirehoseARN' }.output_value

    # Get the resource names from the ARNs
    iam_role_name = iam_role_arn.split(':')[-1].split('/')[-1]
    firehose_name = firehose_arn.split(':')[-1].split('/')[-1]
else
    raise "Unknown provider: #{provider}"
end

describe iam_role(iam_role_name) do
    it { should exist }
end

describe firehose(firehose_name) do
    it { should exist }
end

describe lambda("spec-test-cf-#{user}") do
    it { should exist }
    its(:timeout) { should eq 120 }
    its(:runtime) { should eq 'go1.x' }
    its(:handler) { should eq 'main' }
end

describe 'Custom::Invoke' do
    let(:log_group_name) { "/aws/lambda/spec-test-cf-#{user}" }
    let(:cloudwatchlogs) { Aws::CloudWatchLogs::Client.new(region: region) } 

    it 'invokes lambda upon CloudFormation stack completion' do
        response = cloudwatchlogs.describe_log_streams(
            log_group_name: log_group_name,
            descending: true,
            order_by: 'LastEventTime'
        )

        # Fetch the most recent log stream
        log_stream_name = response.log_streams.first.log_stream_name

        log_events = cloudwatchlogs.get_log_events(
            log_group_name: log_group_name,
            log_stream_name: log_stream_name
        )

        # Check for a specific message in the log that indicates a successful invocation
        expect(log_events.events.map(&:message).join).to include("END")
    end
end

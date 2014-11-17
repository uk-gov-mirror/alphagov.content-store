require "rails_helper"
require_relative "../../lib/heartbeat_generator"
require_relative "../../lib/govuk_exchange"

describe "sending a heartbeat message on the queue", :type => :request do
  include MessageQueueHelpers

  around :each do |example|
    @config = YAML.load_file(Rails.root.join("config", "rabbitmq.yml"))[Rails.env].symbolize_keys
    conn = Bunny.new(@config)
    conn.start
    read_channel = conn.create_channel
    ex = read_channel.topic(@config.fetch(:exchange), passive: true)
    @queue = read_channel.queue("", :exclusive => true)
    @queue.bind(ex, routing_key: 'heartbeat.major')
    example.run

    read_channel.close
  end

  it "should place a heartbeat message on the queue" do
    exchange_name = @config.delete(:exchange)
    heartbeat_exchange = GovukExchange.new(exchange_name, config: @config)
    HeartbeatGenerator.new(heartbeat_exchange).generate

    delivery_info, properties, payload = wait_for_message_on(@queue)
    message = JSON.parse(payload)

    expect(properties.content_type).to eq("application/x-heartbeat")
    expect(delivery_info.routing_key).to eq("heartbeat.major")
    expect(message.fetch("hostname")).to eq(Socket.gethostname)
  end
end

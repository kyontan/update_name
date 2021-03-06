# Coding: UTF-8

require 'twitter'

CONSUMER_KEY    = YOUR_CONSUMER_KEY
CONSUMER_SECRET = YOUR_CONSUMER_SECRET
ACCESS_TOKEN    = YOUR_ACCESS_TOKEN
ACCESS_SECRET   = YOUR_ACCESS_SECRET

@rest_client = Twitter::REST::Client.new do |config|
    config.consumer_key        = CONSUMER_KEY
    config.consumer_secret     = CONSUMER_SECRET
    config.access_token        = ACCESS_TOKEN
    config.access_token_secret = ACCESS_SECRET
end

@stream_client = Twitter::Streaming::Client.new do |config|
    config.consumer_key       = CONSUMER_KEY
    config.consumer_secret    = CONSUMER_SECRET
    config.oauth_token        = ACCESS_TOKEN
    config.oauth_token_secret = ACCESS_SECRET
end

@orig_name, @screen_name = [:name, :screen_name].map{|x| @rest_client.user.send(x) }
@regexp = /^(?:RT )?@#{@screen_name} *update_name( (.+))?/

def update_name(status)
    begin
        name = status.text.match(@regexp)[2]
        if name && 20 < name.length
            text = "長すぎます"
            raise "New name is too long"
        end

        @rest_client.update_profile(name: name)
        text = @orig_name == name ? "元に戻しました" : "#{name} に改名しました!"
    rescue => e
        p status, status.text
        p e
    ensure
        @rest_client.update("@#{status.user.screen_name} #{text}")
    end
end

@stream_client.user do |object|
    next unless object.is_a? Twitter::Tweet and object.text.match(@regexp)

    unless object.text.start_with? "RT"
        update_name(object)
    else
        puts "RTです"
    end
end

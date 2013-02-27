require 'json'
require 'grocer/invalid_payload_error'

module Grocer
  # Public: An object used to send notifications to APNS.
  class Notification
    attr_accessor :identifier, :expiry, :device_token, :alert, :badge, :sound,
                  :custom

    # Public: Initialize a new Grocer::Notification. You must specify at least an `alert` or `badge`.
    #
    # payload - The Hash of notification parameters and payload to be sent to APNS.:
    #           :device_token - The String representing to device token sent to APNS.
    #           :alert        - The String or Hash to be sent as the alert portion of the payload. (optional)
    #           :badge        - The Integer to be sent as the badge portion of the payload. (optional)
    #           :sound        - The String representing the sound portion of the payload. (optional)
    #           :expiry       - The Integer representing UNIX epoch date sent to APNS as the notification expiry. (default: 0)
    #           :identifier   - The arbitrary value sent to APNS to uniquely this notification. (default: 0)
    def initialize(payload = {})
      @identifier = 0

      payload.each do |key, val|
        send("#{key}=", val)
      end
    end

    def to_bytes
      validate_payload
      payload = encoded_payload

      [
        1,
        identifier,
        expiry_epoch_time,
        device_token_length,
        sanitized_device_token,
        payload.bytesize,
        payload
      ].pack('CNNnH64nA*')
    end

    private

    def validate_payload
      fail NoPayloadError unless alert || badge
      fail InvalidPayloadError if encoded_payload.bytesize > 256
    end

    def encoded_payload
      JSON.dump(payload_hash)
    end

    def payload_hash
      aps_hash = { }
      aps_hash[:alert] = alert if alert
      aps_hash[:badge] = badge if badge
      aps_hash[:sound] = sound if sound

      { aps: aps_hash }.merge(custom || { })
    end

    def expiry_epoch_time
      expiry.to_i
    end

    def sanitized_device_token
      device_token.tr(' ', '') if device_token
    end

    def device_token_length
      32
    end
  end
end

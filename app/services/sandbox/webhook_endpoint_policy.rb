require "ipaddr"
require "resolv"
require "uri"

module Sandbox
  class WebhookEndpointPolicy
    UnsafeEndpointError = Class.new(StandardError)

    BLOCKED_HOSTNAMES = %w[localhost localhost.localdomain].freeze
    BLOCKED_IP_RANGES = [
      "0.0.0.0/8",
      "10.0.0.0/8",
      "100.64.0.0/10",
      "127.0.0.0/8",
      "169.254.0.0/16",
      "172.16.0.0/12",
      "192.0.0.0/24",
      "192.0.2.0/24",
      "192.168.0.0/16",
      "198.18.0.0/15",
      "198.51.100.0/24",
      "203.0.113.0/24",
      "224.0.0.0/4",
      "240.0.0.0/4",
      "::/128",
      "::1/128",
      "64:ff9b:1::/48",
      "100::/64",
      "2001:2::/48",
      "2001:db8::/32",
      "fc00::/7",
      "fe80::/10",
      "ff00::/8"
    ].map { |range| IPAddr.new(range) }.freeze

    def self.resolve!(uri)
      raise UnsafeEndpointError, "webhook_url must be http or https" unless uri.is_a?(URI::HTTP)

      host = uri.host.to_s.downcase
      raise UnsafeEndpointError, "webhook host is required" if host.blank?
      raise UnsafeEndpointError, "webhook host is not allowed" if blocked_hostname?(host)

      addresses = Resolv.getaddresses(host)
      raise UnsafeEndpointError, "webhook host could not be resolved" if addresses.empty?

      blocked_address = addresses.find { |address| blocked_address?(address) }
      raise UnsafeEndpointError, "webhook host resolves to a blocked network" if blocked_address.present?

      addresses.first
    rescue Resolv::ResolvError, IPAddr::InvalidAddressError => error
      raise UnsafeEndpointError, "#{error.class}: #{error.message}"
    end

    def self.blocked_hostname?(host)
      return false if private_addresses_allowed?

      normalized = host.delete_suffix(".")
      BLOCKED_HOSTNAMES.include?(normalized)
    end

    def self.blocked_address?(address)
      return false if private_addresses_allowed?

      ip_address = IPAddr.new(address)
      BLOCKED_IP_RANGES.any? { |range| range.include?(ip_address) }
    end

    def self.private_addresses_allowed?
      ENV["WEBHOOK_ALLOW_PRIVATE_ADDRESSES"] == "true"
    end

    private_class_method :blocked_hostname?, :blocked_address?, :private_addresses_allowed?
  end
end

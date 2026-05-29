module Security
  class RateLimiter
    WINDOW = 60.seconds

    def self.check!(key:, limit:)
      return if limit.blank? || limit.to_i <= 0

      cache_key = "rate-limit:#{key}:#{Time.current.to_i / WINDOW.to_i}"
      count = Rails.cache.increment(cache_key, 1, expires_in: WINDOW)
      count ||= Rails.cache.write(cache_key, 1, expires_in: WINDOW) && 1

      raise RateLimitExceeded.new(retry_after: WINDOW.to_i) if count > limit.to_i
    end
  end
end

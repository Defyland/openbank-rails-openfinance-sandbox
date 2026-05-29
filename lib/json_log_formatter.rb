require "json"

class JsonLogFormatter < Logger::Formatter
  def call(severity, time, progname, msg)
    payload = {
      timestamp: time.utc.iso8601(3),
      severity: severity,
      progname: progname
    }.merge(normalize_message(msg))

    if payload["request_id"].blank? && defined?(Current) && Current.request_id.present?
      payload[:request_id] ||= Current.request_id
    end

    if payload["correlation_id"].blank? && defined?(Current) && Current.correlation_id.present?
      payload[:correlation_id] ||= Current.correlation_id
    end
    payload[:tags] = current_tags if respond_to?(:current_tags) && current_tags.present?

    "#{JSON.generate(payload.compact)}\n"
  end

  private

  def normalize_message(message)
    case message
    when Hash
      message.deep_stringify_keys
    when String
      stripped_message = strip_current_tags(message)
      parse_json_payload(stripped_message) || { message: stripped_message }
    when Exception
      {
        message: message.message,
        error_class: message.class.name
      }
    else
      { message: message.to_s }
    end
  end

  def strip_current_tags(message)
    return message unless respond_to?(:current_tags) && current_tags.present?

    current_tags.reduce(message) do |formatted_message, tag|
      formatted_message.sub(/\A\[#{Regexp.escape(tag)}\]\s*/, "")
    end
  end

  def parse_json_payload(message)
    return unless message.start_with?("{", "[")

    parsed = JSON.parse(message)
    parsed if parsed.is_a?(Hash)
  rescue JSON::ParserError
    nil
  end
end

require "json_schemer"
require "uri"
require "yaml"

module OpenapiContractAssertions
  def assert_openapi_document_valid
    errors = openapi_contract.validate.to_a
    assert_empty format_schema_errors(errors), "OpenAPI document is invalid"
  end

  def assert_openapi_response(path, method, status, payload)
    schema = openapi_document.dig(
      "paths", path, method.to_s,
      "responses", status.to_s,
      "content", "application/json", "schema"
    )
    assert schema, "Missing OpenAPI response schema for #{method.to_s.upcase} #{path} #{status}"

    errors = openapi_contract.ref(schema_pointer(path, method, status)).validate(payload).to_a
    assert_empty format_schema_errors(errors), "#{method.to_s.upcase} #{path} #{status} response does not match OpenAPI"
  end

  private

  def openapi_document
    @openapi_document ||= YAML.load_file(Rails.root.join("openapi.yaml"))
  end

  def openapi_contract
    @openapi_contract ||= JSONSchemer.openapi(openapi_document)
  end

  def schema_pointer(path, method, status)
    segments = [
      "paths", path, method.to_s,
      "responses", status.to_s,
      "content", "application/json", "schema"
    ]
    "#/#{segments.map { |segment| escape_json_pointer_segment(segment) }.join('/')}"
  end

  def escape_json_pointer_segment(segment)
    URI::DEFAULT_PARSER.escape(segment.to_s.gsub("~", "~0").gsub("/", "~1"))
  end

  def format_schema_errors(errors)
    errors.map do |error|
      "#{error.fetch('data_pointer', '/')}: #{error.fetch('type')} #{error['details'].inspect}".strip
    end
  end
end

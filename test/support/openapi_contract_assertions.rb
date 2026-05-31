require "yaml"

module OpenapiContractAssertions
  def assert_openapi_response(path, method, status, payload)
    schema = openapi_document.dig(
      "paths", path, method.to_s,
      "responses", status.to_s,
      "content", "application/json", "schema"
    )
    assert schema, "Missing OpenAPI response schema for #{method.to_s.upcase} #{path} #{status}"

    assert_schema_matches(schema, payload, "$")
  end

  private

  def openapi_document
    @openapi_document ||= YAML.load_file(Rails.root.join("openapi.yaml"))
  end

  def assert_schema_matches(schema, value, path)
    schema = resolve_ref(schema)

    Array(schema["allOf"]).each { |nested_schema| assert_schema_matches(nested_schema, value, path) }

    allowed_types = Array(schema["type"])
    return if value.nil? && allowed_types.include?("null")

    assert_equal schema["const"], value, "#{path} should equal #{schema['const'].inspect}" if schema.key?("const")
    assert_includes schema["enum"], value, "#{path} should be one of #{schema['enum'].inspect}" if schema.key?("enum")

    type = allowed_types.find { |candidate| candidate != "null" }
    type ||= "object" if schema.key?("properties")
    type ||= "array" if schema.key?("items")

    case type
    when "object"
      assert_kind_of Hash, value, "#{path} should be an object"
      Array(schema["required"]).each do |required_key|
        assert value.key?(required_key), "#{path} should include required key #{required_key.inspect}"
      end
      schema.fetch("properties", {}).each do |key, property_schema|
        assert_schema_matches(property_schema, value[key], "#{path}.#{key}") if value.key?(key)
      end
    when "array"
      assert_kind_of Array, value, "#{path} should be an array"
      value.each_with_index do |item, index|
        assert_schema_matches(schema.fetch("items"), item, "#{path}[#{index}]")
      end
    when "string"
      assert_kind_of String, value, "#{path} should be a string"
    when "integer"
      assert_kind_of Integer, value, "#{path} should be an integer"
    when "number"
      assert_kind_of Numeric, value, "#{path} should be a number"
    when "boolean"
      assert_includes [ true, false ], value, "#{path} should be a boolean"
    end
  end

  def resolve_ref(schema)
    return schema unless schema.is_a?(Hash) && schema["$ref"].present?

    ref = schema.fetch("$ref")
    ref.delete_prefix("#/").split("/").reduce(openapi_document) { |node, key| node.fetch(key) }
  end
end

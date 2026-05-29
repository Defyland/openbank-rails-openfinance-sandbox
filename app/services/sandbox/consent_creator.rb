module Sandbox
  class ConsentCreator
    def self.call!(developer_app:, params:, correlation_id:)
      customer = SandboxCustomer.find_by!(document_number: params.fetch(:customer_document_number))
      permissions = Array(params.fetch(:permissions)).map(&:to_s).uniq

      Consent.create!(
        developer_app: developer_app,
        sandbox_customer: customer,
        external_id: params[:external_id],
        permissions: permissions,
        expires_at: params[:expires_at] || 90.days.from_now,
        correlation_id: correlation_id,
        metadata: params.fetch(:metadata, {})
      )
    end
  end
end

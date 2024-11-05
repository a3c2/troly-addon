module Integrations::A3C2::Fees

	include Interfaces::Gateway::Fees::Subscriptions
	
	def gateway_monthly_fee
		return [] unless @plan_selected.present?

		price = self.t("plans_details.#{@plan_selected}.price")

		return [price, @plan_selected]
	end

end
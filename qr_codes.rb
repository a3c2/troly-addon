module Integrations::A3C2::QrCodes

	include Interfaces::Branding::QrCodes # to include this gateway when the Processor::Branding is processing QrCodes

	# Remove Gateway-specifc tokens used on the company record
	def uninstalled_cleanup_qr_codes
	
		self.additional_qr_codes_for_model(Product).each do |qr_code|
			@integration.company.products.each{ |o| o.redirectable_remove_short_code!(qr_code) }
		end

	end
	
	include Interfaces::Branding::QrCodes::Products

	def additional_qr_codes_for_model klass

		klass = klass.to_s # ?? although we are passing a activerecord.class, it seems the active record delegation through records.each makes the 'klass' a different object than the original record class, ence `record.class == Product' fails INSIDE his method, not before, not after calling it.

		return %w(elabel) 																			if klass == 'Product'
		return []
	end

	def qr_code_elabel_for_product record, user_id=nil
		record.redirectable_add_short_code('elabel')
		return [record.redirectable_short_url('elabel')]
	end

end
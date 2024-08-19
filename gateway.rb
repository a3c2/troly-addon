class Integrations::A3C2::Gateway < Integrations::BaseGateway

	include Processors::Interfaces::Branding::Companies

	@params_to_store = {

		fore_colour_start: '',			 # text colour: gradient start
		fore_colour_end: '',				 # text colour: gradient end
		fore_gradient_type: '',			 # text colour
		back_colour: '',			 # background colour
		eye_inside_colour: '',	 # eye inside colour
		eye_outsite_colour: '',	 # eye outside colour

		qr_style:'circle',
		qr_style_eye:'frame1',
		qr_style_ball:'ball1',

		qr_logo:false,
		
		qr_code_logo:'',
		qr_code_wrap:'',

		plan_selected:''
	}

	@params_to_operate = [:plan_selected, :qr_code_style, :qr_code_eye]; 

	def gateway_monthly_cost
		return [] unless @plan_selected.present?

		price = self.i18n("plans_details.#{@plan_selected}.price")

		return [price, @plan_selected]
	end

	# Generates a referral code ensuring uniqueness across both Company and CompanyCustomers
	# @return [String] the generated code
	def self.generate_code(length=6)
		characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

		confusing_patterns = [
			'/gq/','/pn/','/mn/','/yz/','/uv/','/ce/',
			'/qg/','/np/','/nm/','/zy/','/vu/','/ec/',
			'/lb/','/ie/','/ao/',
			'/bl/','/ei/','/oa/',
			'/l1/','/b6/','/o0/','/g9/','/q9/',
			'/1l/','/6b/','/0o/','/9g/','/9q/',
			'/Il/',
			'/lI/',
			'/TI/','/DO/','/CG/','/LI/','/NM/','/PB/','/FR/','/UO/','/UV/','/EF/','/VW/','/XY/',
			'/IT/','/OD/','/GG/','/IL/','/MN/','/BP/','/RF/','/OU/','/VU/','/FE/','/WW/','/YX/',
			'/SL/',
			'/LS/',
			'/G6/','/F7/','/Z2/','/Q2/','/O0/','/B8/','/D0/','/S5/','/S8/','/Y5/','/Z7/','/T7/','/U0/','/U4/',
			'/6G/','/7F/','/2Z/','/2Q/','/0O/','/8B/','/0D/','/5S/','/8S/','/5Y/','/7Z/','/7T/','/0U/','/4U/',
			'/08/','/39/','/38/','/49/','/58/','/53/','/68/','/71/',
			'/80/','/93/','/83/','/94/','/85/','/35/','/86/','/17/'
		]

		code = ''
		gen = Random.new

		while code.length < length do
			code += characters[gen.rand(0..(characters.size-1))]

			confusing_patterns.each do |patt|
				code.gsub!(patt, '')
			end
		end

		return code
	end


	# Generates a QR code that when scanned will link to the provided url
	# @param [String] url the url to link to with the QR code
	# @return [MemoryFileBuffer] the QR code (to be used for a tagged uploader field), e.g. Product.qr_code
	def generate_qr_code url

		return nil if ['qr_codes','basic_labels','advanced_labels'].exclude?(@plan_selected)

		company = @integration.company
		fg = @colour_fg || company&.branding_colour_primary || '#2f363a'
		bg = @colour_bg || company&.branding_colour_bg || '#ffffff'
		eye_in = @colour_eye_in || accent
		eye_out = @colour_eye_out || accent
		
		style = @qr_style || 'circle' # dot, circle-zebra, circle-zebra-vertical 
		style_in = @qr_style_ball || 'ball1'
		style_out = @qr_style_eye || 'frame1'
		logo = nil;#company&.branding_qr_code_logo.present? ? company&.logo_img&.thumbnail.url : ''

		# if campaign&.length == 2
		# 	campaign_params = "utm_source=QR&utm_medium=#{campaign[0]}&utm_campaign=#{campaign[1]}"
		# 	if url.match(/#/).nil?
		# 		url = url.match(/\?/).nil? ? "#{url}?#{campaign_params}" : "#{url}&#{campaign_params}"
		# 	else
		# 		url = url.match(/\?/).nil? ? url.gsub(/#/, "?#{campaign_params}#") : url.gsub(/#/, "&#{campaign_params}#")
		# 	end
		# end

		config = {
			"body":style,"eye":style_out,"eyeBall":style_in,
			"erf1":["fh"],"erf2":[],"erf3":["fh","fv"],"brf1":["fh"],"brf2":[],"brf3":["fh","fv"],
			#"erf1":[],"erf2":[],"erf3":[],"brf1":[],"brf2":[],"brf3":[],
			"bodyColor":fg,"bgColor":bg,
			"eye1Color":eye_out,"eye2Color":eye_out,"eye3Color":eye_out,"eyeBall1Color":eye_in,"eyeBall2Color":eye_in,"eyeBall3Color":eye_in,
			"gradientColor1":"","gradientColor2":"","gradientType":"linear","gradientOnEyes":"false","logo":logo.present? && @qr_logo ? logo : '', "logoMode": (@qr_logo && logo.present? ? 'clean' : 'default')
		}

		params = {
			download: true,
			file: 'svg',
			data: url,
			#size: 1080,
			config: config.to_json
		}

		sleep(5) # that API really doesn't like multiple calls each second
		response = HTTParty.get('https://api.qrcode-monkey.com/qr/custom', { :query => params })

		if response.body.match(/Too many requests:/)
			Rails.logger.tagged('ApplicationHelper').tagged(__method__).fatal "QR code generation failed: #{response.body}"
			return nil
		end

		# consideration for change https://qrcodedynamic.com/qr/url or https://rqrcode.com/

		return MemoryFileBuffer.new("#{SecureRandom.hex}.svg", response.body)
		
	end

	def create_qrcode_product(params, channel=nil, user_id=nil)
		
		params = HashWithIndifferentAccess.new(params).with_defaults!(
			integration_id: @integration.id
		)

		raise ArgumentError, "Missing required parameter 'product_id'" unless params['product_id'].present?

		Processors::Branding.generate_qr_for_products(params['product_id'], params, channel, user_id)
	end

	def create_qrcode_products(params, channel=nil, user_id=nil)
		
		params = HashWithIndifferentAccess.new(params).with_defaults!(
			integration_id: @integration.id
		)

		Processors::Branding.generate_qr_for_products(@integration.company.products, params, channel, user_id)
	end

end
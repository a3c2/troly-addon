class Integrations::A3C2::Gateway < Integrations::BaseGateway

	include Integrations::A3C2::QrCodes
	include Integrations::A3C2::Fees

	PARAMS_TO_STORE = {

		plan_selected:''
	}

	PARAMS_TO_OPERATE = [:plan_selected];


end
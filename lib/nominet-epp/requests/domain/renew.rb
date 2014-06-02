module NominetEPP
  module Domain
    class Renew < Request
      def initialize(name, exp_date, period = nil)
        @command = EPP::Domain::Renew.new(name, exp_date, period)
      end
    end
  end
end

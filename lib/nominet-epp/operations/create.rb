module NominetEPP
  module Operations
    # EPP Create Operation
    module Create
      # Register a domain name with Nominet.
      #
      # The returned hash has the following keys
      # - (String) +:name+ --    Domain name registered
      # - (Time) +:crDate+ --    Domain creation date
      # - (Time) +:exDate+ --    Domain expiration date
      # - (Hash) +:account+ --   Created account data (if returned)
      #
      # The +:account+ hash contains the following keys
      # - (String) +:roid+ --    Account ID
      # - (String) +:name+ --    Account Name
      # - (Array) +:contacts+ -- Account contacts
      #
      # The +:contacts+ array contains hashes of the following keys
      # - (String) +:roid+ --    Contact ID
      # - (String) +:name+ --    Contact Name
      # - (String) +:type+ --    Contact type if set
      # - (Integer) +:order+ --  Contacts order in the list of contacts
      #
      # @param [String] name Domain name to register
      # @param [String, Hash] acct
      # @param [String, Array] nameservers Nameservers to set for the domain
      # @param [Hash] options Registration options
      # @option options [String] :period
      # @option options [String] :first_bill
      # @option options [String] :recur_bill
      # @option options [String] :auto_bill
      # @option options [String] :next_bill
      # @option options [String] :notes
      # @raise [ArgumentError] invalid option keys
      # @return [false] registration failed
      # @return [Hash] Domain creation data
      def create(name, acct, nameservers, options = {})
        raise ArgumentError, "options allowed keys are period, first_bill, recur_bill, auto_bill, next_bill, notes" unless (options.keys - [:period, :first_bill, :recur_bill, :auto_bill, :next_bill, :notes]).empty?

        @resp = @client.create do
          domain('create') do |node, ns|
            node << XML::Node.new('name', name, ns)

            if period = options.delete(:period)
              unit = period[-1..1]
              num = period.to_i.to_s
              p = XML::Node.new('period', num, ns);
              p['unit'] = unit
              node << p
            end

            # node << XML::Node.new('auto-period', '', ns) # placeholder

            node << XML::Node.new('account', nil, ns).tap do |acct_xml|
              acct_xml << create_account(acct, ns)
            end

            node << domain_ns_xml(nameservers, ns)

            # Enforce correct sequencing of option fields
            [:first_bill, :recur_bill, :auto_bill, :next_bill, :notes].each do |key|
              next if options[key].nil? || options[key] == ''
              node << XML::Node.new(key.to_s.gsub('_', '-'), options[key], ns)
            end
          end
        end

        return false unless @resp.success?

        creData = @resp.data.find('//domain:creData', namespaces).first
        h = { :name => node_value(creData, 'domain:name'),
          :crDate => Time.parse(node_value(creData, 'domain:crDate')),
          :exDate => Time.parse(node_value(creData, 'domain:exDate')) }
        unless creData.find('domain:account').first.nil?
          h[:account] = created_account(creData.find('domain:account/account:creData', namespaces).first)
        end
        h
      end
      
      private
        # Create the account payload
        #
        # @param [String, Hash] acct Account ID or New account fields
        # @param [XML::Namespace] domain_ns +:domain+ namespace
        # @raise [ArgumentError] acct must be a String or a Hash of account fields
        # @return [XML::Node]
        def create_account(acct, domain_ns)
          if acct.kind_of?(String)
            XML::Node.new('account-id', acct, domain_ns)
          elsif acct.kind_of?(Hash)
            account('create') do |node, ns|
              node << XML::Node.new('name', acct[:name], ns)
              account_fields_xml(acct, node, ns)
            end
          else
            raise ArgumentError, "acct must be String or Hash"
          end
        end

        # Collects created account information
        #
        # @param [XML::Node] creData XML
        # @return [Hash]
        def created_account(creData)
          { :roid => node_value(creData, 'account:roid'),
            :name => node_value(creData, 'account:name'),
            :contacts => created_contacts(creData.find(
              'account:contact', namespaces)) }
        end

        # Collects created account contacts
        #
        # @param [XML::Node] account_contacts Account contacts
        # @return [Hash]
        def created_contacts(account_contacts)
          account_contacts.map do |cont|
            { :type => cont['type'],
              :order => cont['order'] }.merge(
                created_contact(cont.find('contact:creData', namespaces).first))
          end
        end

        # Collects create contact information
        #
        # @param [XML::Node] creData XML
        # @return [Hash]
        def created_contact(creData)
          { :roid => node_value(creData, 'contact:roid'),
            :name => node_value(creData, 'contact:name') }
        end
    end
  end
end

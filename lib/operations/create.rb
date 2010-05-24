module NominetEPP
  module Operations
    module Create
      # options
      #  period
      #  first_bill
      #  recur_bill
      #  auto_bill
      #  next_bill
      #  notes
      def create(name, acct, nameservers, options = {})
        raise ArgumentError, "options allowed keys are period, first_bill, recur_bill, auto_bill, next_bill, notes" unless (options.keys - [:period, :first_bill, :recur_bill, :auto_bill, :next_bill, :notes]).empty?

        resp = @client.create do
          domain('create') do |node, ns|
            node << XML::Node.new('name', name, ns)

            options[:period] && node << XML::Node.new('period', options.delete(:period), ns)

            acct_xml = XML::Node.new('account', nil, ns)
            acct_xml << create_account(acct, ns)
            node << acct_xml

            node << create_nameservers(nameservers, ns)

            options.each do |key, value|
              node << XML::Node.new(key.to_s.gsub('_', '-'), value, ns)
            end
          end
        end

        return false unless resp.success?

        creData = resp.data.find('/domain:creData', data_namespaces(resp.data)).first
        h = { :name => node_value(creData, 'domain:name'),
          :crDate => Time.parse(node_value(creData, 'domain:crDate'))
          :exDate => Time.parse(node_value(creData, 'domain:exDate')) }
        unless creData.find('domain:account').first.nil?
          h[:account] = created_account(creData.find('domain:account/account:creData', data_namespaces(resp.data)).first) }
        end
        h
      end
      
      private
        def create_account(acct, domain_ns)
          if acct.kind_of?(String)
            XML::Node.new('account-id', acct, domain_ns)
          elsif acct.kind_of?(Hash)
            account('create') do |node, ns|
              node << XML::Node.new('name', acct[:name], ns)
              node << XML::Node.new('trad-name', acct[:trad_name], ns)
              node << XML::Node.new('type', acct[:type], ns)
              node << XML::Node.new('opt-out', acct[:opt_out], ns)

              acct[:contacts].each_with_index do |cont, i|
                c = XML::Node.new('contact', nil, ns)
                c['order'] = i
                node << (c << create_account_contact(cont))
              end

              node << create_account_address(acct[:addr], ns)
            end
          else
            raise ArgumentError, "acct must be String or Hash"
          end
        end
        def create_account_contact(cont)
          raise ArgumentError, "Contact allowed keys are name, email, phone and mobile" unless (cont.keys -[:name, :email, :phone, :mobile]).empty?
          raise ArgumentError, "Contact requires name and email keys" unless cont.has_key?(:name) && cont.has_key?(:email)

          contact('create') do |node, ns|
            cont.each do |key, value|
              node << XML::Node.new(key, value, ns)
            end
          end
        end
        def create_account_address(addr, ns)
          raise ArgumentError, "Address allowed keys are street, locality, city, county, postcode, country" unless (addr.keys - [:street, :locality, :city, :county, :postcode, :country]).empty?

          addr = XML::Node.new('addr', nil, ns)
          addr.each do |key, value|
            addr << XML::Node.new(key, value, ns)
          end

          addr
        end
        def create_nameservers(nameservers, ns)
          wrap = XML::Node.new('ns', nil, ns)

          case nameservers.class
          when String
            wrap << (XML::Node.new('host', nil, ns) << XML::Node.new('hostName', nameservers, ns))
          when Array
            nameservers.each do |nameserver|
              wrap << create_host_node(nameserver, ns)
            end
          else
            raise ArgumentError, "nameservers must either be a string or array of strings"
          end

          wrap
        end
        def create_host_node(hostname, ns)
          host = XML::Node.new('host', nil, ns)

          case hostname.class
          when String
            host << XML::Node.new('hostName', hostname, ns)
          when Hash
            host << XML::Node.new('hostName', hostname[:name], ns)
            if hostname[:v4]
              n = XML::Node.new('hostAddr', hostname[:v4], ns)
              n['ip'] = 'v4'
              host << n
            end
            if hostname[:v6]
              n = XML::Node.new('hostAddr', hostname[:v6], ns)
              n['ip'] = 'v6'
              host << n
            end
          end

          host
        end
        def created_account(creData)
          { :roid => node_value(creData, 'account:roid'),
            :name => node_value(creData, 'account:name'),
            :contacts => created_contacts(creData.find(
              'account:contact', creData.namespaces.find_by_prefix('account').to_s)) }
        end
        def created_contacts(account_contacts)
          account_contacts.map do |cont|
            { :type => cont['type'],
              :order => cont['order'] }.merge(
                created_contact(cont.find('contact:creData',
                  cont.namespaces.find_by_prefix('contact').to_s).first))
          end
        end
        def created_contact(creData)
          { :roid => node_value(creData, 'contact:roid'),
            :name => node_value(creData, 'contact:name') }
        end
    end
  end
end
module NominetEPP
  module Operations
    # EPP List Operatons
    module List
      # Obtain a list of domains, and optionally their details, which either
      # expire or were registered in the month given.
      #
      # @param [Symbol] type Listing type, either +:expiry+ or +:month+
      # @param [String, #strftime] date Date of either expiry or registration to list
      # @param [String] fields Verbosity of the response, either 'none' or 'all'
      # @raise [ArgumentError] type must be +:expiry+ or +:month+
      # @return [nil] list failed
      # @return [Array<String>] list of domains
      # @return [Array<Hash>] list of domains with details
      def list(type, date, fields = 'none')
        raise ArgumentError, "type must be :expiry or :month" unless [:expiry, :month].include?(type)

        date = date.strftime("%Y-%m") if date.respond_to?(:strftime)
        resp = @client.info do
          domain('list') do |node, ns|
            node << XML::Node.new(type, date, ns)
            node << XML::Node.new('fields', fields, ns)
          end
        end

        return nil unless resp.success?

        if fields == 'none'
          resp.data.find('//domain:name', namespaces).map do |node|
            node.content.strip
          end
        else
          resp.data.find('//domain:infData', namespaces).map do |infData|
            hash = {}
            infData.children.reject{|n| n.empty?}.each do |node|
              key = node.name.gsub('-', '_').to_sym
              case node.name
              when 'account'
                hash[:account] = info_account(node)
              when 'ns'
                hash[:ns] = node.find('domain:host', namespaces).map do |hostnode|
                  { :name => node_value(hostnode, 'domain:hostName'),
                    :v4 => node_value(hostnode, 'domain:hostAddr[@ip="v4"]'),
                    :v6 => node_value(hostnode, 'domain:hostAddr[@ip="v6"]') }.reject{|k,v| v.nil?}
                end
              when /date/i
                hash[key] = Time.parse(node.content.strip)
              else
                hash[key] = node.content.strip
              end
            end
            hash
          end
        end
      end

      # list of all tags that accept tag changes along with their handshake settings
      #
      # The returned array of hashes contain the following keys
      # - (String) +:registrar_tag+ -- TAG name
      # - (String) +:name+ -- Name of the TAG owner
      # - (String) +:trad_name+ -- TAG trading name
      # - (BOOL) +:handshake+ -- Whether the TAG accepts handshakes
      #
      # @return [false] failure
      # @return [Array<Hash>] tag details
      def tag_list
        resp = @client.info do
          tag('list')
        end

        return false unless resp.success?

        resp.data.find('//tag:infData', namespaces).map do |node|
          { :registrar_tag => node_value(node, 'tag:registrar-tag'),
            :name =>          node_value(node, 'tag:name'),
            :trad_name =>     node_value(node, 'tag:trad-name'),
            :handshake =>     node_value(node, 'tag:handshake') == 'Y' }
        end
      end
    end
  end
end
module NominetEPP
  module Custom
    class TagListResponse < BasicResponse
      def initialize(response)
        raise ArgumentError, "must be an EPP::Response" unless response.kind_of?(EPP::Response)
        super
      end

      def tags
        @tags ||= parse_infdata
      end

      def namespaces
        { 'tag' => 'http://www.nominet.org.uk/epp/xml/nom-tag-1.0' }
      end

      protected
        def parse_infdata
          tags = {}
          
          @response.data.find('//tag:infData', namespaces).each do |node|
            tag  = node.find('tag:registrar-tag').first.content.strip
            name = node.find('tag:name').first.content.strip
            handshake = node.find('tag:handshake').first.content.strip
            
            trad = node.find('tag:trad-name').first
            trad = trad && trad.content.strip
            
            tags[tag] = { 'name' => name, 'handshake' => handshake == 'Y' }
            tags[tag]['trad_name'] = trad if trad
          end
          
          tags
        end
    end
  end
end

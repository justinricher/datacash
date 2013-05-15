require 'rest_client'
require 'builder'

module Datacash
  class Client

    ENDPOINTS = {
      live: "https://mars.transaction.datacash.com/Transaction",
      test: "https://accreditation.datacash.com/Transaction/cnp_a"
    }

    def initialize(options={})
      @client      = options.fetch(:client)
      @password    = options.fetch(:password)
      @environment = options.fetch(:environment, :test)
    rescue KeyError => e
      raise ArgumentError, "Missing option - #{e}"
    end

    def query(datacash_reference)
      Response.new(
        send_to_datacash(query_xml(datacash_reference))
      )
    end

    def request(&block)
      Response.new(
        send_to_datacash(xml_wrapper {|xml| yield(xml)})
      )
    end

    private
    attr_reader :client, 
      :password, 
      :environment

    def rest_client
      RestClient
    end

    def endpoint
      ENDPOINTS[environment]
    end

    def send_to_datacash(xml_string)
      rest_client.post(endpoint, xml_string, content_type: :xml, accept: :xml)
    end

    def query_xml(reference)
      xml_wrapper do |xml|
        xml.tag! :HistoricTxn do
          xml.tag! :method, 'query'
          xml.tag! :reference, reference
        end
      end
    end

    def xml_wrapper
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.tag! :Request do
        xml.tag! :Authentication do
          xml.tag! :client,   client
          xml.tag! :password, password
        end
        xml.tag! :Transaction do
          yield(xml)
        end
      end
      xml.target!
    end
  end
end

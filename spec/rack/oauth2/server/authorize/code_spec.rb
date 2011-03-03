require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize::Code do
  let(:request)            { Rack::MockRequest.new app }
  let(:redirect_uri)       { 'http://client.example.com/callback' }
  let(:authorization_code) { 'authorization_code' }  
  let(:response)           { request.get "/?response_type=code&client_id=client&redirect_uri=#{redirect_uri}" }

  context 'when approved' do
    subject { response }
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = authorization_code
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}?code=#{authorization_code}" }

    context 'when redirect_uri already includes query' do
      let(:redirect_uri) { 'http://client.example.com/callback?k=v' }
      its(:location)     { should == "#{redirect_uri}&code=#{authorization_code}" }
    end

    context 'when redirect_uri is missing' do
      let :app do
        Rack::OAuth2::Server::Authorize.new do |request, response|
          response.code = authorization_code
          response.approve!
        end
      end
      it do
        expect { response }.should raise_error AttrRequired::AttrMissing
      end
    end

    context 'when code is missing' do
      let :app do
        Rack::OAuth2::Server::Authorize.new do |request, response|
          response.redirect_uri = redirect_uri
          response.approve!
        end
      end
      it do
        expect { response }.should raise_error AttrRequired::AttrMissing
      end
    end
  end

  context 'when denied' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        request.access_denied!
      end
    end
    it 'should redirect with error in query' do
      response.status.should == 302
      error_message = {
        :error => :access_denied,
        :error_description => Rack::OAuth2::Server::Authorize::ErrorMethods::DEFAULT_DESCRIPTION[:access_denied]
      }
      response.location.should == "#{redirect_uri}?#{error_message.to_query}"
    end
  end
end
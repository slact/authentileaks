require 'minitest_helper'

describe Authentileaks::RootController do
  include Rack::Test::Methods

  def app
    Authentileaks::Application.new
  end

  describe 'GET /' do
    it 'must be ok' do
      get '/'
      last_response.must_be :ok?
      last_response.body.must_match /Hello Authentileaks!/
    end
  end
end

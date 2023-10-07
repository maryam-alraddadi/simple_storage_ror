class Api::V1::BlobsController < ApplicationController
  
  include ApiKeyAuthenticatable
  
  prepend_before_action :authenticate_with_api_key!, only: [:index]
  
  def index
    
    request = {
      http_method: 'get',
      url: 'http://localhost:9000/testing-sig/myimage.png',
      headers: {},
      body: ''
    }
    
    creds = {
      secret_access_key: 'TUpMkJLnOOGktQQbgohizrt1CRtm13ekfUQqYdGy',
      access_key_id: 'yf5mNMwULNCw6Zc6tTdc'
    }
    
    signer = Signer.new(creds)
    res = signer.sign_request(request)
    
    render json: res, status: 200
  end
end

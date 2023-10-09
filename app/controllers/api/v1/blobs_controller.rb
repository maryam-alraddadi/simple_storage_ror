class Api::V1::BlobsController < ApplicationController
  
  include ApiKeyAuthenticatable
  
  prepend_before_action :authenticate_with_api_key! 
  
  @@minio_url = "#{Rails.application.credentials.MINIO_HOST}/#{Rails.application.credentials.MINIO_BUCKET_NAME}"
  @@creds = {
    secret_access_key: "#{Rails.application.credentials.MINIO_SECRET_ACCESS_KEY}",
    access_key_id: "#{Rails.application.credentials.MINIO_ACCESS_KEY_ID}"
  }
  
  # @@minio_url = "#{ENV.fetch('MINIO_HOST')}/#{ENV.fetch('MINIO_BUCKET_NAME')}"
  # @@creds = {
  #   secret_access_key: "#{ENV.fetch('MINIO_SECRET_ACCESS_KEY')}",
  #   access_key_id: "#{ENV.fetch('MINIO_ACCESS_KEY_ID')}"
  # }
  
  @@storage_service = "MINIO"
  
  
  def show
    
    case @@storage_service
    when "MINIO"
      blob = get_file_from_bucket(params[:id])
    end
    
    render json: blob, status: 200
  end
  
  
  def index
  end
  
  
  def create
    
    id = params[:id]
    data = params[:data]

    if !(id.to_s.match(/\h{8}-(\h{4}-){3}\h{12}/))
      render json: "id should be valid UUID", status: 400 
      return
    end
    
    
    case @@storage_service
    when "MINIO"
      blob = save_file_to_bucket(id, data)
    end

    render json: blob, status: 201
  end
  
  
  private 
  
  def get_file_from_bucket(id)
    
    blob = Blob.find_by(id: id)
    
    request = {
      http_method: 'get',
      url: "#{blob.data}",
      headers: {},
      body: ''
    }
    
    signer = Signer.new(@@creds)
    headers = signer.sign_request(request)
    response = HTTParty.get(request[:url], body: request[:body], headers: headers)
    
    if response.code == 200
      str = response.to_s
      data = Base64.encode64(str).gsub(/\n/, "")
      blob.data = data
      blob
    else
      raise Exception.new('something bad happened!')
    end

  end
  
  
  def save_file_to_bucket(id, data)
    
    file = convert_base64_to_file(data)
    
    request = {
      http_method: 'put',
      url: "#{@@minio_url}/#{id}",
      headers: {},
      body: file
    }
    
    signer = Signer.new(@@creds)
    headers = signer.sign_request(request)
    response = HTTParty.put(request[:url], body: request[:body], headers: headers)
    
    if response.code == 200
      size = file_size_to_mb(file.size)
      blob = Blob.create({:id => id, :data => request[:url], "size" => size})
      blob
    else
      raise Exception.new('something bad happened!')
    end
    
  end
  
  
  def convert_base64_to_file(base64_data)
    return base64_data unless base64_data.present? && base64_data.is_a?(String)

    decoded_file = Base64.decode64(base64_data)

    decoded_file
  end
  
  def file_size_to_mb(size)
    '%.2f' % (size.to_f / 2**20)
  end
  
end

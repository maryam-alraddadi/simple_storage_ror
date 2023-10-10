class Api::V1::BlobsController < ApplicationController
  
  include ApiKeyAuthenticatable
  
  prepend_before_action :authenticate_with_api_key! 
  
  @@LOCAL_DIR = ENV.fetch('LOCAL_DIR_PATH')
  @@minio_url = "#{ENV.fetch('MINIO_HOST')}/#{ENV.fetch('MINIO_BUCKET_NAME')}"
  @@creds = {
    secret_access_key: "#{ENV.fetch('MINIO_SECRET_ACCESS_KEY')}",
    access_key_id: "#{ENV.fetch('MINIO_ACCESS_KEY_ID')}"
  }
  
  @@storage_service = ENV.fetch('STORAGE_SERVICE')
  
  
  def show
    
    id = params[:id]
    
    case @@storage_service
    when "MINIO"
      blob = get_file_from_bucket(id)
    when "LOCALDIR"
      blob = get_file_from_dir(id)
    when "DB"
      blob = get_file_from_db(id)
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
    when "LOCALDIR"
      blob = save_file_to_dir(id, data)
    when "DB"
      blob = save_file_to_db(id, data)
    end
    
    render json: {id: blob.id}, status: 201
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
      data = convert_binary_to_base64(response)
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
  
  
  
  def save_file_to_dir(id, data)
    path = "#{@@LOCAL_DIR}/#{id}"
    file_data = convert_base64_to_file(data)
    size = file_size_to_mb(file_data.size)
    
    File.open(path, 'wb') { |file| file.write(file_data) }
    
    blob = Blob.create({:id => id, :data => path, "size" => size})
    blob
  end
  
  
  def get_file_from_dir(id)

    blob = Blob.find_by(id: id)
    bdata = File.open(blob.data, 'rb') { |f| f.read }
    blob.data = convert_binary_to_base64(bdata)

    blob
  end
  
  
  def save_file_to_db(id, data)
    file = convert_base64_to_file(data)
    size = file_size_to_mb(file.size)

    blob = Blob.create({:id => id, "size" => size})
    blob_storage = blob.create_blob_storage({:data => file})
    blob.data = blob_storage.id
    blob
  end
  
  
  
  def get_file_from_db(id)

    blob = blob = Blob.find_by(id: id)
    blob.data = convert_binary_to_base64(blob.blob_storage.data)
    blob
    
  end
  
  
  # def save_file_to_ftp(id, data)

  #   file = convert_base64_to_file(data)
  #   tempfile = Tempfile.new("filename")
  #   tempfile.binmode
  #   tempfile.write(file)
    
  #   Net::FTP.open('127.0.0.1:21', 'one', '1234') do |ftp|
  #     ftp.passive = true
      
  #     ftp.putbinaryfile(tempfile)
  #   end
  # end
  
  
  
  def convert_base64_to_file(base64_data)
    return base64_data unless base64_data.present? && base64_data.is_a?(String)

    decoded_file = Base64.decode64(base64_data)

    decoded_file
  end
  
  
  def convert_binary_to_base64(binary)
    str = binary.to_s
    Base64.encode64(str).gsub(/\n/, "")
  end
  

  def file_size_to_mb(size)
    '%.2f' % (size.to_f / 2**20)
  end
  
end

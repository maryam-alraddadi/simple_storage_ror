class Signer
    
    def initialize(credentials)
        @service = 's3'
        @region = 'us-east-1'
        @secret_access_key = credentials[:secret_access_key]
        @access_key_id = credentials[:access_key_id]
    end

    def sign_request(request)
        
        http_method = request[:http_method].upcase
        url = URI.parse(request[:url].to_s)
        headers = request[:headers]
        datetime = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
        date = datetime[0,8]
        
        # hash the body, if theres no body hash the empty string
        content_sha256 ||= sha256_hexdigest(request[:body] || '')
        
        # set required headers
        headers['host'] = host(url) # headers['host'] || url
        headers['x-amz-date'] = datetime
        headers['x-amz-content-sha256'] ||= content_sha256
        puts headers
        
        ## Gen sig
        creq = canonical_request(http_method, url, headers, content_sha256)
        sts = string_to_sign(datetime, creq)
        sig = signature(date, sts)
        
        headers['authorization'] = authorization_header(date, headers, sig)
        
        return headers
    end

    
    def host(uri)
        if uri.default_port == uri.port
          uri.host
        else
          "#{uri.host}:#{uri.port}".strip
        end
    end
    
    
    def sha256_hexdigest(value)
        if (File === value)
        OpenSSL::Digest::SHA256.file(value).hexdigest
        else
        OpenSSL::Digest::SHA256.hexdigest(value)
        end
    end
    
    
    def canonical_request(http_method, url, headers, content_sha256)
        
        # <HTTPMethod>\n
        # <CanonicalURI>\n
        # <CanonicalQueryString>\n
        # <CanonicalHeaders>\n
        # <SignedHeaders>\n
        # <HashedPayload>
        
        [
          http_method,
          url.path,
          '',
          canonical_headers(headers) + "\n",
          signed_headers(headers),
          content_sha256,
        ].join("\n")
    end
    
    
    def canonical_headers(headers)
        
        # Lowercase(<HeaderName1>)+":"+Trim(<value>)+"\n"
        # Lowercase(<HeaderName2>)+":"+Trim(<value>)+"\n"
        # ...
        # Lowercase(<HeaderNameN>)+":"+Trim(<value>)+"\n"
        
        headers = headers.inject([]) do |hdrs, (k,v)|
          hdrs << [k,v]
        end
        
        headers = headers.sort_by(&:first)
        headers.map{|k,v| "#{k}:#{v.to_s}" }.join("\n")
    end
    
      
    def signed_headers(headers)
        
        # host;x-amz-content-sha256;x-amz-date
        
        headers.inject([]) do |signed_headers, (header, _)|
        signed_headers << header
        end.sort.join(';')
    end

    def string_to_sign(datetime, canonical_request)
        
        # Algorithm \n
        # RequestDateTime \n
        # CredentialScope  \n
        # HashedCanonicalRequest
        
        [
          'AWS4-HMAC-SHA256',
          datetime,
          credential_scope(datetime[0,8]),
          sha256_hexdigest(canonical_request),
        ].join("\n")
    end
    
    def credential_scope(date)

        # YYYYMMDD/region/service/aws4_request
        
        [date,@region, @service,'aws4_request'].join('/')
        
    end
    
    
    def signature(date, string_to_sign)
        
        # DateKey = HMAC-SHA256("AWS4"+"<SecretAccessKey>", "<YYYYMMDD>")
        # DateRegionKey = HMAC-SHA256(<DateKey>, "<aws-region>")
        # DateRegionServiceKey = HMAC-SHA256(<DateRegionKey>, "<aws-service>")
        # SigningKey = HMAC-SHA256(<DateRegionServiceKey>, "aws4_request")
        
        date_key = hmac_sha256("AWS4" + @secret_access_key, date)
        date_region_key = hmac_sha256(date_key, @region)
        date_region_service_key = hmac_sha256(date_region_key, @service)
        signing_key  = hmac_sha256(date_region_service_key, 'aws4_request')
        hex_hmac_sha256(signing_key, string_to_sign)
    end
    
    
    def hmac_sha256(key, value)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, value)
    end
    
    
    def hex_hmac_sha256(key, value)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, value)
    end
    
    
    def authorization_header(date, headers, signature)
        
        # Authorization: AWS4-HMAC-SHA256
        # Credential=AKIAIOSFODNN7EXAMPLE/20220830/us-east-1/ec2/aws4_request,
        # SignedHeaders=host;x-amz-date,
        # Signature=calculated-signature
        
        [
          "AWS4-HMAC-SHA256 Credential=#{@access_key_id}/#{credential_scope(date)}",
          "SignedHeaders=#{signed_headers(headers)}",
          "Signature=#{signature}",
        ].join(', ')
    end
    
    

end
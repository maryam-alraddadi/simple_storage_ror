# File Storage with Ruby on Rails

  

This Ruby on Rails application provides APIs to store files as blobs, using a single interface for multiple storage backends:

-   AWS S3 on MinIO
-   Database table
-   Local file system


#### dependencies
- Ruby 3.2.2
- Rails 7.0.8
- Postgres
  
#### Setting up the environment

copy `.env.exmaple` into a new file with the name `.env`
populate the file with your environment variables:

|env variable| description |
|--|--|
`DATABASE_HOST` | host name of the server where the database is running
`DATABASE_NAME` | name of database used by the application
`DATABASE_USER` | username of db login
`DATABASE_PASSWORD` | password of db login
| `API_KEY_HMAC_SECRET_KEY` | random 32 byte string used to generate HMAC digests of api-key, can be created with `SecureRandom.hex(32)` |
| `STORAGE_SERVICE` | to configure the storage backend, set this environment variable to one of the following values `MINIO - LOCALDIR - DB` |
|`MINIO_HOST` | if `STORAGE_SERVICE` is set to "MINIO", configure minio variables, this one defines the full url for minio service ex: `http://127.0.0.1:9000`|
| `MINIO_BUCKET_NAME` | the bucket that would be used for storing the files, if using `docker-compose.yml` make sure to update minio/mc |
| `MINIO_ACCESS_KEY_ID` | used for accessing the minio service, can be created through MinIO console
| `MINIO_SECRET_ACCESS_KEY` | the secret for the access key id|
|`LOCAL_DIR_PATH`| if `STORAGE_SERVICE` is set to "LOCALDIR", specify the path to the storage directory 


#### Running the app

`docker-compose.yml` is setup to spin up the application and its dependent containers, it creates a minio service and runs minio/mc to create a private bucket, create and initlizes a postgres db and builds and run the rails application.

in the project root run:
 `docker compose up`

### API

#### Authentication

the application uses Api keys as `Bearer ` tokens to authenticate users, only authenticated users can upload and retrieve files.
to generate an Api key, first create a user

```bash
curl --location --request POST 'http://localhost:3000/api/v1/users' \
--header 'Content-Type: application/json' \
--data-raw '{
	"user": {
		"username": "meme",
		"password": "1234"
	}
}'
```
then you generate you first api key using your credentials as basic auth


```bash
curl -X POST http://localhost:3000/api-keys -u meme:1234

# {
#    "id":  1,
#    "bearer_id":  2,
#    "bearer_type":  "User",
#    "created_at":  "2023-10-10T19:24:45.617Z",
#    "updated_at":  "2023-10-10T19:24:45.617Z",
#    "token":  "96a32f9e878411612a6af54c396a7519"
# }
```

you can then use the generated  `token` to authenticated your requests.

#### Blobs

to upload a file, you must have a valid `id` in the form of a UUID, a UUID is a 32-character hexadecimal string represented in five groups separated by hyphens.
the second field `data` represents the file encoded in `base64`


```bash
curl --request POST 'http://localhost:3000/api/v1/blobs' \
     --header 'Authorization: Bearer 96a32f9e878411612a6af54c396a7519' \
     --header 'Content-Type: application/json' \
     --data-raw '{
			"id": "3f333df6-90a4-4fda-8dd3-9485d27cee36",
			"data": "aGVsbG8gZnJvbSBkb2Nz"
       		}'
```


##### Retrieve

retrieve the file using the same `id` used in upload:
```bash
curl --request GET 'http://localhost:3000/api/v1/blobs/3f333df6-90a4-4fda-8dd3-9485d27cee36' \
     --header 'Authorization: Bearer 96a32f9e878411612a6af54c396a7519'
```




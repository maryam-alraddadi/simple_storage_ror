require "test_helper"

class BlobsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get blobs_index_url
    assert_response :success
  end
end

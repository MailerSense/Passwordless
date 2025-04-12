defmodule Passwordless.FileUploads.S3 do
  @moduledoc """
  Dependency-free S3 Form Upload using HTTP POST sigv4

  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html

  ## Setup

  Create an S3 bucket and enable CORS. Click on Permissions, scroll down to "Cross-origin resource sharing (CORS)" and add:

        [
          {
            "AllowedHeaders": [
              "*"
            ],
            "AllowedMethods": [
              "PUT",
              "POST"
            ],
            "AllowedOrigins": [
              "*"
            ],
            "ExposeHeaders": []
          }
        ]

  You also need ACLs enabled.
  Go to Bucket > Permissions Tab.
  Scroll to Object Ownership and click on Edit.
  Set ACLs to enabled. Object ownership should be "Bucket owner preferred".
  Save.

  Create an IAM user with permissions to upload to the bucket. See https://medium.com/founders-coders/image-uploads-with-aws-s3-elixir-phoenix-ex-aws-step-1-f6ed1c918f14.

  Add the following environment variables to your .envrc:

      export AWS_ACCESS_KEY=""
      export AWS_SECRET=""
      export AWS_REGION=""
      export S3_FILE_UPLOAD_BUCKET=""

  In your live view mount() function:

      socket
      |> allow_upload(:avatar,
          accept: ~w(.jpg .jpeg .png .gif .svg .webp),
          max_entries: 1,
          external: &Passwordless.FileUploads.S3.presign_upload/2
        )}

  When you want to retrieve the URLs:

      def handle_event("submit", %{"user" => user_params}, socket) do
        uploaded_files = Passwordless.FileUploads.S3.consume_uploaded_entries(socket, :avatar)
        # => ["http://your-bucket.s3.your-region.amazonaws.com/file"]

        # Do something with the uploaded files
      end
  """

  @doc """
  Signs a form upload.

  The configuration is a map which must contain the following keys:

    * `:region` - The AWS region, such as "eu-west-1"
    * `:access_key_id` - The AWS access key id
    * `:secret_access_key` - The AWS secret access key

  Returns a map of form fields to be used on the client via the JavaScript `FormData` API.

  ## Options

    * `:key` - The required key of the object to be uploaded.
    * `:max_file_size` - The required maximum allowed file size in bytes.
    * `:content_type` - The required MIME type of the file to be uploaded.
    * `:expires_in` - The required expiration time in milliseconds from now
      before the signed upload expires.

  ## Examples

      config = %{
        region: "eu-west-1",
        access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
        secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
      }

      {:ok, fields} =
        S3.sign_form_upload(config, "my-bucket",
          key: "public/my-file-name",
          content_type: "image/png",
          max_file_size: 10_000,
          expires_in: :timer.hours(1)
        )
  """

  @prefix "customer-media/app/logos/"

  @spec presign_upload(map(), map()) :: {:ok, map(), map()} | {:error, term()}
  def presign_upload(entry, socket) do
    bucket = get_bucket()
    key = @prefix <> Util.random_string(32) <> Path.extname(entry.client_name)

    {:ok, url} =
      :s3
      |> ExAws.Config.new()
      |> ExAws.S3.presigned_url(:put, bucket, key,
        expires_in: 3600,
        query_params: [{"Content-Type", entry.client_type}]
      )

    {:ok, %{uploader: "S3", key: key, url: url}, socket}
  end

  @spec consume_uploaded_entries(Phoenix.LiveView.Socket.t(), any) :: list
  def consume_uploaded_entries(socket, uploads_key) do
    Phoenix.LiveView.consume_uploaded_entries(socket, uploads_key, fn %{key: key}, entry ->
      {:ok, {get_cdn_url() <> key, entry}}
    end)
  end

  # Private

  defp get_bucket do
    get_in(Passwordless.config(:s3), [:customer_media, :bucket])
  end

  defp get_cdn_url do
    get_in(Passwordless.config(:s3), [:customer_media, :cdn_url])
  end
end

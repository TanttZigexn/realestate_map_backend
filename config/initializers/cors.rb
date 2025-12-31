# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow all origins
    # In production, specify your frontend domain
    origins Rails.env.development? ? "*" : ENV.fetch("ALLOWED_ORIGINS", "https://hkt-team13.zigexn.vn")

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "Content-Type", "Authorization" ]
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Rental Search API V1',
        version: 'v1',
        description: 'API for searching rental rooms on map with PostGIS support',
        contact: {
          name: 'API Support'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        schemas: {
          GeoJSONFeature: {
            type: 'object',
            properties: {
              type: { type: 'string', example: 'Feature' },
              geometry: {
                type: 'object',
                properties: {
                  type: { type: 'string', example: 'Point' },
                  coordinates: {
                    type: 'array',
                    items: { type: 'number' },
                    example: [105.8542, 21.0285]
                  }
                }
              },
              properties: {
                type: 'object',
                properties: {
                  id: { type: 'integer' },
                  title: { type: 'string' },
                  price: { type: 'integer' },
                  area: { type: 'number', nullable: true },
                  address: { type: 'string', nullable: true },
                  roomType: { type: 'string', enum: ['room', 'studio', 'apartment'] },
                  status: { type: 'string', enum: ['available', 'rented'] },
                  description: { type: 'string', nullable: true },
                  phone: { type: 'string', nullable: true },
                  phoneFormatted: { type: 'string', nullable: true }
                }
              }
            }
          },
          GeoJSONFeatureCollection: {
            type: 'object',
            properties: {
              type: { type: 'string', example: 'FeatureCollection' },
              features: {
                type: 'array',
                items: { '$ref' => '#/components/schemas/GeoJSONFeature' }
            }
          }
          },
          Error: {
            type: 'object',
            properties: {
              error: { type: 'string' }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end

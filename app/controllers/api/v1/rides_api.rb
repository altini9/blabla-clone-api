# frozen_string_literal: true

module API
  module V1
    class RidesApi < Grape::API
      helpers API::ParamsHelper
      helpers Pundit

      helpers do
        params :ride_params do
          optional :start_location_country, type: String, desc: "user start location country"
          optional :start_location_address, type: String, desc: "user start location address"
          optional :start_location_latitude, type: String, desc: "user start location latitude"
          optional :start_location_longitude, type: String, desc: "user start location longitude"
          optional :destination_location_country, type: String, desc: "user destination location country"
          optional :destination_location_address, type: String, desc: "user destination location address"
          optional :destination_location_latitude, type: String, desc: "user destination location latitude"
          optional :destination_location_longitude, type: String, desc: "user destination location longitude"
          requires :places, type: Integer, desc: "user places"
          requires :start_date, type: String, desc: "user start_date"
          requires :price, type: String, desc: "user price"
          requires :currency, type: String, desc: "user currency"
          requires :car_id, type: Integer, desc: "user car_id"
        end

        def ride
          @ride ||= Ride.includes(:driver, :car, :start_location, :destination_location)
            .find(params[:id])
        end

        def user_ride
          @user_ride ||= current_user.rides_as_driver.find(params[:id])
        end

        def ride_owner?
          ride.driver.id == current_user.id if current_user.present?
        end

        def user
          @user ||= User.find_by(id: params[:user_id])
        end
      end

      resource :rides do
        desc "Return a ride options"
        get :options do
          cars = current_user.cars
          {
            currencies: Ride.currencies.keys,
            cars: ActiveModel::Serializer::CollectionSerializer.new(
              cars, serializer: CarSimpleSerializer
            ),
          }
        end

        desc "Return list of rides"
        params do
          use :pagination_params
          optional :start_location, type: String, desc: "filter by start_location"
          optional :destination_location, type: String, desc: "filter by destination_location"
          optional :start_date, type: String, desc: "filter by start date"
          optional :hide_full, type: Boolean, desc: "hide full rides filter"
          optional :filters
          optional :search
        end
        get do
          data = declared(params)
          rides = RideFilters::RidesFinder.new(data, current_user).call
          options = { page: data[:page], per: data[:per] }
          serialized_paginated_results(rides, RideSerializer, options)
        end

        desc "Return user rides as driver"
        params do
          use :pagination_params
          requires :user_id, type: Integer, desc: "user id"
          optional :filters
          optional :search
        end
        get :as_driver do
          authorize(:ride, :show_rides_as_driver?)
          data = declared(params)
          rides = RideFilters::RidesAsDriverFinder.new(data, current_user).call
          options = { page: data[:page], per: data[:per] }
          serialized_paginated_results(rides, RideSerializer, options)
        end

        desc "Return user rides as passenger"
        params do
          use :pagination_params
          requires :user_id, type: Integer, desc: "user id"
          optional :filters
          optional :search
        end
        get :as_passenger do
          authorize(:ride, :show_rides_as_passenger?)
          data = declared(params)
          rides = RideFilters::RidesAsPassengerFinder.new(data, current_user).call
          options = { page: data[:page], per: data[:per] }
          serialized_paginated_results(rides, RideSerializer, options)
        end

        desc "Create a ride"
        params do
          use :ride_params
        end
        post serializer: RideShowSerializer do
          authorize(:ride, :create?)
          data = declared(params, include_missing: false)
          created_ride = RideCreator.new(current_user, data).call

          unprocessable_entity(created_ride.errors.messages) unless created_ride.valid?
          created_ride
        end

        params do
          requires :id, type: Integer, desc: "ride id"
        end
        route_param :id do
          desc "Return a ride"
          get serializer: RideShowSerializer do
            ride
          end

          desc "Update a ride"
          params do
            use :ride_params
          end
          put serializer: RideShowSerializer do
            authorize(ride, :update?)
            data = declared(params, include_missing: false)
            created_ride = RideUpdater.new(current_user, user_ride, data).call

            unprocessable_entity(created_ride.errors.messages) unless created_ride.valid?
            created_ride
          end
        end
      end
    end
  end
end

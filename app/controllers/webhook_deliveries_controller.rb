class WebhookDeliveriesController < ApplicationController
  def index
    page = params[:page] || 1
    size = params[:size] || 10
    client_application_id = params[:client_application_id]

    cache_key = "webhook_deliveries/#{client_application_id}/page/#{page}/size/#{size}"

    # Use Rails.cache to cache the API response across requests
    @webhook_deliveries = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      response = ClientApplicationService.fetch_webhook_deliveries(
        session[:access_token],
        client_application_id: client_application_id, page: page, size: size
      )

      response.map do |webhook_delivery_data|
        build_webhook_delivery(webhook_delivery_data)
      end
    end

    @total_pages = 1 # FIX ME: response.headers["X-Total-Count"]
    @current_page = page.to_i
  rescue => e
    @error = e.message
  end

  def show
    webhook_delivery_id = params[:id]
    response = ClientApplicationService.fetch_webhook_delivery(
      session[:access_token],
      id: webhook_delivery_id
    )

    @webhook_delivery = build_webhook_delivery(response)
  rescue => e
    @error = e.message
  end

  private

  def build_webhook_delivery(data)
    WebhookDelivery.new(
      id: data[:id],
      response_status: data[:response_status],
      error_class: data[:error_class],
      created_at: data[:created_at],
      completed_at: data[:completed_at],
      webhook_event: data[:webhook_event],
      webhook_id: data[:webhook_id],
      webhook_url: data[:webhook_url]
    )
  end

  def client_application_partner_params
    params.require(:client_application).permit(:client_application_id)
  end
end

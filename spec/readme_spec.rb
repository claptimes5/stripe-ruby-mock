
describe 'README examples' do

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "creates a stripe customer" do

    # This doesn't touch stripe's servers nor the internet!
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'void_card_token'
    })
    expect(customer.email).to eq('johnny@appleseed.com')
  end


  it "mocks a declined card error" do
    # Prepares an error for the next stripe request
    StripeMock.prepare_card_error(:card_declined)

    begin
      # Note: The next request of ANY type will raise your prepared error
      Stripe::Charge.create()
    rescue Stripe::CardError => error
      expect(error.http_status).to eq(402)
      expect(error.code).to eq('card_declined')
    end
  end


  it "raises a custom error" do
    custom_error = Stripe::AuthenticationError.new('Did not provide favourite colour', 400)
    StripeMock.prepare_error(custom_error)

    begin
      # Note: The next request of ANY type will raise your prepared error
      Stripe::Invoice.create()
    rescue Stripe::AuthenticationError => error
      expect(error.http_status).to eq(400)
      expect(error.message).to eq('Did not provide favourite colour')
    end
  end

  it "has built-in card errors" do
    StripeMock.prepare_card_error(:incorrect_number)
    StripeMock.prepare_card_error(:invalid_number)
    StripeMock.prepare_card_error(:invalid_expiry_month)
    StripeMock.prepare_card_error(:invalid_expiry_year)
    StripeMock.prepare_card_error(:invalid_cvc)
    StripeMock.prepare_card_error(:expired_card)
    StripeMock.prepare_card_error(:incorrect_cvc)
    StripeMock.prepare_card_error(:card_declined)
    StripeMock.prepare_card_error(:missing)
    StripeMock.prepare_card_error(:processing_error)
  end

  it "mocks a stripe webhook" do
    event = StripeMock.mock_webhook_event('customer.created')

    customer_object = event.data.object
    expect(customer_object.id).to_not be_nil
    expect(customer_object.active_card).to_not be_nil
    # etc.
  end

  it "can override default webhook values" do
    event = StripeMock.mock_webhook_event('customer.created', {
      :id => 'cus_my_custom_value',
      :email => 'joe@example.com'
    })
    # Alternatively:
    # event.data.object.id = 'cus_my_custom_value'
    # event.data.object.email = 'joe@example.com'
    expect(event.data.object.id).to eq('cus_my_custom_value')
    expect(event.data.object.email).to eq('joe@example.com')
  end

end
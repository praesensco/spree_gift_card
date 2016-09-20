SpreeGiftCard
=============

SpreeGiftCard is an extension and one stop solution to integrate GiftCard functionality in your spree application.

* This integration enables you to Create and Apply Gift card Functionality, through products which are GiftCard enabled.

* GiftCard can be bought as any normal product from your spree store. When gift card is bought, details are sent to recipient, which includes GiftCard `Code`, on succesful order payment.

* Gift cards can be redeemed by entering a unique GiftCard `Code` during checkout.

## Installation

1. Just add this line to your `Gemfile`:
  ```ruby
  gem 'spree_gift_card',           github: 'vinsol/spree_gift_card',   branch: 'x-x-stable'
  ```

2. Execute the following commands in respective order:

   ```ruby
    bundle install
    ```

   ```ruby
    rails g spree_gift_card:install
    ```
    seed the default data with:
   ```ruby
    rails g spree_gift_card:seed
    ```

3. Working
---

* Admin can create `Gift Card` through

    `Admin -> Products -> New`

    while creating a New Gift Card, check `is gift card`, which means the product is GiftCard.
* Once GiftCard is created, it is visible to customer.
* When purchasing a GiftCard, a form is rendered to user, on which one can fill the `Value`,`Email`, `Recipient name` and `Note`. Once your order-payment is successfully captured, the GiftCard will be send to the email mentioned in GiftCard form.
* The `Email` will contain details of GiftCard, amount, code, sender's email and note.
* One can redeem the GiftCard by applying gift card code at payment step.
* Besides, One can also add GiftCard shipment category and method, if gift card is meant for email delivery.

Contributing
------------

1. Fork the repo.
2. Clone your repo.
3. Run `bundle install`.
4. Run `bundle exec rake test_app` to create the test application in `spec/test_app`.
5. Make your changes.
6. Ensure specs pass by running `bundle exec rspec spec`.
7. Submit your pull request.

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_gift_card/factories'
```


Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License

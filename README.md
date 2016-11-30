SpreeGiftCard
=============

SpreeGiftCard is an extension and one stop solution to integrate gift card functionality in a spree application.

* This extension allows the admin to create a gift card, by just enabling it from Admin end.

* Gift card is treated and can be bought as any normal product from your spree store. When a gift card is successfully bought, its details are sent to recipient's email address, which includes gift card `Code`.

* Recipient can then redeem the gift card by entering the unique gift card `Code` during checkout on payment step.

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

* A gift card is created by default when you seed data. Admin can also create `gift card` through

    `Admin -> Products -> New`

    while creating a new gift card, check `is gift card`, which means the product is gift card.
* Once gift card is created, it is visible to customer.
* One needs to add gift card shipping category to a shipping method to purchase a gift card.
* When purchasing a gift card, a form is rendered to user, on which one can fill the `value`,`email`, `recipient name` and `note`. Once your order-payment is successfully captured, the gift card will be send to the email mentioned in gift card form.
* The `Email` will contain details of gift card, amount, code, sender's email and note.
* One can redeem the gift card by applying gift card code at payment step.

**Here is a detailed article with screenshot http://vinsol.com/spreecommerce-gift-card**
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

Copyright (c) 2012 Jeff Dutil, released under the New BSD License

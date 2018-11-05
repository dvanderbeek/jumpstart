# Rails Jumpstart

It's like Laravel Spark, for Rails. All your Rails apps should start off with a bunch of great defaults.

**Note:** Requires Rails 5.2

## Getting Started

Jumpstart is a Rails template, so you pass it in as an option when creating a new app.

#### Requirements

You'll need the following installed to run the template successfully:

* Ruby 2.5+
* bundler - `gem install bundler`
* rails - `gem install rails`
* Yarn - `brew install yarn` or [Install Yarn](https://yarnpkg.com/en/docs/install)

#### Creating a new app

```bash
rails new myapp -d postgresql -m https://raw.githubusercontent.com/dvanderbeek/jumpstart/master/template.rb
```

Or if you have downloaded this repo, you can reference template.rb locally:

```bash
rails new myapp -d postgresql -m template.rb
```

Set credentials for Stripe

```bash
EDITOR="subl --wait" rails credentials:edit
```

```yml
development:
  stripe:
    public_key: pk_testasdf123
    secret_key: sk_testasdf123
    signing_secret: whsec_testasdf123

production:
  stripe:
    public_key: pk_liveasdf123
    secret_key: sk_liveasdf123
    signing_secret: whsec_testasdf123
```

Import stripe plans

```bash
rake sync_stripe
```

#### Cleaning up

```bash
rails db:drop
spring stop
cd ..
rm -rf myapp
```

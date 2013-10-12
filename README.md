# Yodlee Now

Get real easy access the new Yodlee REST API via this Ruby Gem. This API is the easiest way ever to access financial data at the tens of thousands of institutions partnered with Yodlee.  See http://yodlee.com and http://devnow.yodlee.com.

## Installation

Add this line to your application's Gemfile:

    gem 'yodlee_now'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yodlee_now

## Usage

If you are starting from zero - sign up for developer access at [https://devnow.yodlee.com/].  You will get your cobrandLogin and cobrandPassword here.

 * Note your cobrandPassword is NOT the password you choose when creating your account, see the Developer Info tab once logged in.  
 * Start with the test accounts given to you.  The login is shown on the developer info page, the password is the login + '#123' (eg for test user name 'sbMemtestaccount1' the password would be 'sbMemtestaccount1#123')
 * You may wish to add an actual account to a test user to view actual financial data.  

Some sample code for irb or rails' console:

    require 'yodlee_now'
    cobSession = YodleeNow::CobrandSession.new
    cobSession.login('cobrandLogin','cobrandPassword')
    yodUser = YodleeNow::User.new
    yodUser.login('testUserLogin','testUserPassword',cobSession.sessionToken)
    yodSummaries = YodleeNow::ItemSummaries.new
    yodSummaries.load(cobSession.sessionToken,yodUser.sessionToken)
    yodSummaries.card_txn_test

This will return sample transaction data for the last account added by the test user referenced above.

TODO: Lots. Clean up sample txn system.  Add user registration and account enrollment.  Build multiTXN parsers.

TODO: Write tests

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Yodlee Now

Yodlee's new REST API allows easy access to financial data at the tens of thousands of institutions partnered with Yodlee.  This gem wraps the REST API.  See http://yodlee.com and http://devnow.yodlee.com for more detail on Yodlee's offerings.

This gem currently relies on Rails for some helper methods.  

## Installation

Add this line to your application's Gemfile:

    gem 'yodlee_now'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yodlee_now

## Usage

If you are starting from zero - sign up for developer access at https://devnow.yodlee.com/.  You will get your cobrandLogin and cobrandPassword here.

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

Note the login and load methods return true or false so you can test for response success.  Check the error method on the object if you receive a false response.

    yodSummaries.error

For a full JSON response of a user's item summaries:

    yodSummaries.response

However, that is a ton of data. This might be easier:

    yodSummaries.institution_names

    => [[10001641, "DagBank"]]

The `institution_names` method returns an array of financial institution ids and names from the Item Summaries. To get a list of accounts within an institution, call the id of the institution name.  

    yodSummaries.account_names(10001641)

    => [[10002121, "TESTDATA1", "xxxx3xxx"], [10002120, "TESTDATA", "xxxx3xxx"]]

Now you can get a big JSON dump of account data for each institution and account by passing the id of each:

    yodSummaries.account_data(10001641,10002121)

Again, a ton of data.  For credit card accounts, get full JSON transaction data with:

    yodSummaries.card_transactions(10001641,10002121)

And if you just want to collect the basics - transaction ID, transaction date, date posted, description, name, categories, amount and currency - in simple array format:

    yodSummaries.card_transaction_basics(10001641,10002121)

    
TODO: Lots. Clean up sample txn system.  Add user registration and account enrollment.  Build multiTXN parsers.

TODO: Write tests

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Yodlee Now

Yodlee's new REST API allows easy access to financial data at the tens of thousands of institutions partnered with Yodlee.  This gem wraps the REST API.  See http://yodlee.com and http://devnow.yodlee.com for more detail on Yodlee's offerings.

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


#### Authenticate your Cobrand, then Register or Log In a User

Try this in irb or rails' console:

    require 'yodlee_now'
    cobSession = YodleeNow::CobrandSession.new
    cobSession.login(YourCobrandLogin,YourCobrandPassword)
    yodUser = YodleeNow::User.new

Now log in the user
    
    yodUser.login(YourTestUserLogin,YourTestUserPassword,cobSession.sessionToken)

or register a user
    
    yodUser.register('sample@email.com','UserName','password',cobSession.sessionToken)

#### Add a Financial Site for the User

Now you can search for a financial site to add for that user - in this example, let's search for 'chase':

    yodSite = YodleeNow::Site.new

    yodSite.search(cobSession.sessionToken,yodUser.sessionToken,'chase')

For the entire JSON response of all matches for institutions containing 'chase' - check out
    
    yodSite.response

The gem also has a helper method, useful for a quick HTML select if you want the user to choose their institution (see the example of this on the Yodlee developer site, where you can add institutions for your test users):

    yodSite.basics

Once you have chosen the correct siteId, you can get load a custom login form for that site with:

    @form_fields = yodSite.login_form(siteId)

All you need to present an HTML form is here.  What you need to do to proceed is to inject a field called "value" into each field of the array.  So if you want to present the form fields, you could do this (HAML view):

    -@form_fields.each do |field|
      .field=text_field_tag field["name"], :placeholder => field["displayName"]

Save the @form_fields JSON in the session. Then, after restoring the @form_fields from the session and validating your user input, you could place this in the controller:
    
    @form_fields.each do |field|
      field['value'] => params[field['name']]
    end

Then send the JSON back to the Yodlee Now Gem:
    
    yodSite.add_account(cobSession.sessionToken,yodUser.sessionToken,siteId,@form_fields)

And make sure to check 

    yodSite.response

#### Review User's Accounts

A user can have several *Accounts* at one financial *Site*.  To get to a user's transactions, it is convenient to use the specific accountId within a Site.

    yodAccounts = YodleeNow::AccountSummary.new
    yodAccounts.load(cobSession.sessionToken,yodUser.sessionToken)

The full response from Yodlee:

    yodAccounts.response

And a perhaps helpful summary from the Gem:

    yodAccounts.basics

#### Getting a User's Transactions

First, let's start with a basic search.  The accountId- the last field - is technically optional, but recommended.  Get it from the yodAccounts.basics or yodAccounts.response method above.  

    yodTxns = YodleeNow::TransactionDetails.new
    yodTxns.search_request(cobSession.sessionToken,yodUser.sessionToken, accountId)

There are several other options for the search_request method - the above suffices to start.  See the User Search Request section below for details.  Once the search request executes you can get to all data returned with

    yodTxns.response

or cherry pick some basic info with

    basics = yodTxns.basics

This returns the total number of transactions 
    
    basics[:numberOfHits]

and also the first 50 transactions, by default.

    basics[:transactions]

To load a different range of transactions within the total number of hits, execute

    yodTxns.additional_txns(startNum,endNum)

#### The User Search Request

The full options of the gem's search request are:

    yodTxns.search_request(cobSession.sessionToken,yodUser.sessionToken, accountId, startDateTime, 
      endDateTime, options)

The options has is based on the variables outlined in the Yodlee documentation for this method, http://developer.yodlee.com/Indy_FinApp/Aggregation_Services_Guide/REST_API_Reference/executeUserSearchRequest  Note that the gem prepends the "transactionSearchRequest." portion of the Yodlee variable name.


    
TODO: Better error handling -unified. DRY up API calls. Write tests.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

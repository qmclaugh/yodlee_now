require "yodlee_now/version"
require 'uri'
require 'net/ssh'
require 'net/http'
require 'json'
require 'nori'

module YodleeNow

  YODLEE_API_URLS = {
    "END_POINT"=>
      {
        "sandboxBaseUrl"              =>  "https://rest.developer.yodlee.com/services/srest/restserver/v1.0", 
        "stagingBaseUrl"              =>  "https://64.14.28.203/yodsoap/srest/sdkmaster/v1.0", 
        "URL_COBRAND_SESSION_TOKEN"   =>  "/authenticate/coblogin", 
        "URL_USER_SESSION_TOKEN"      =>  "/authenticate/login",
        "URL_SEARCH_SITES"            =>  "/jsonsdk/SiteTraversal/searchSite",
        "URL_GET_SITE_LOGIN_FORM"     =>  "/jsonsdk/SiteAccountManagement/getSiteLoginForm",
        "URL_GET_ITEM_SUMMARIES"      =>  "/jsonsdk/DataService/getItemSummaries", 
        "URL_ADD_SITE_ACCOUNT"        =>  "/jsonsdk/SiteAccountManagement/addSiteAccount",
        "URL_REGISTER_USER"           =>  "/jsonsdk/UserRegistration/register3",
        "URL_USER_SEARCH_REQUEST"     =>  "/jsonsdk/TransactionSearchService/executeUserSearchRequest",
        "URL_GET_USER_TRANSACTIONS"   =>  "/jsonsdk/TransactionSearchService/getUserTransactions",
        "URL_ACCOUNT_SUMMARY"         =>  "/account/summary/all"

      }
    } 

  class CobrandSession
    attr_reader :response, :sessionToken, :error
    def login(cobrandLogin,cobrandPassword)
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_COBRAND_SESSION_TOKEN"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests
      res = http.post(uri.request_uri,"cobrandLogin=#{cobrandLogin}&cobrandPassword=#{cobrandPassword}")
      json = JSON.parse(res.body)
      @response = json

      if json['cobrandConversationCredentials'] && json['cobrandConversationCredentials']['sessionToken']
        @sessionToken = json['cobrandConversationCredentials']['sessionToken']
      else
        @sessionToken = nil
      end
      @error = json['Error']
      @error.nil? ? true : false
    end
  end

  class User
    attr_reader :response, :sessionToken, :error
    def login(login,password,cobSessionToken)
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_USER_SESSION_TOKEN"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests
      res = http.post(uri.request_uri,"login=#{login}&password=#{password}&cobSessionToken=#{cobSessionToken}")
      json = JSON.parse(res.body)
      @response = json
      
      if json['userContext']  && json['userContext']['conversationCredentials']['sessionToken']
        @sessionToken = json['userContext']['conversationCredentials']['sessionToken']
      else
        @sessionToken = nil
      end
      @error = json['Error']
      @error.nil? ? true : false
    end

    def register(email,login,password,cobSessionToken)
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_REGISTER_USER"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests
      res = http.post(uri.request_uri,"userCredentials.objectInstanceType=com.yodlee.ext.login.PasswordCredentials&userCredentials.loginName=#{login}&userCredentials.password=#{password}&userProfile.emailAddress=#{email}&cobSessionToken=#{cobSessionToken}")
      json = JSON.parse(res.body)
      @response = json
      
      if json['userContext']  && json['userContext']['conversationCredentials']['sessionToken']
        @sessionToken = json['userContext']['conversationCredentials']['sessionToken']
      else
        @sessionToken = nil
      end
      @error = json['errorOccured']
      @error == 'true' ? false : true # respond with "true" if no error has occured in the call
    end
  end


  class Site
    attr_reader :response, :error
    def search(cobSessionToken,userSessionToken,siteSearchString)
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_SEARCH_SITES"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests
      res = http.post(uri.request_uri,"cobSessionToken=#{cobSessionToken}&userSessionToken=#{userSessionToken}&siteSearchString=#{siteSearchString}")
      json = JSON.parse(res.body)
      @response=json

      #TODO: Error handling.  Many types of responses from API here, some are JSON some not. For now, return true if call successful.
      true

    end

    def basics
      sites=[]
      self.response.each do |res|
        sites << [res['defaultDisplayName'],res['defaultOrgDisplayName'],res['siteId']]
      end
      return sites
    end

    def details(siteId)
      res = self.response.select{|r| r['siteId'] == siteId}
      res.first
    end

    def login_form(siteId)
      res = self.details(siteId)
      res['loginForms'].first['componentList']
    end

    def form_to_params(cobSessionToken,userSessionToken,siteId,form)
      res = []
      res << "cobSessionToken=#{CGI::escape cobSessionToken}"
      res << "userSessionToken=#{CGI::escape userSessionToken}"
      res << "siteId=#{siteId}"
      form.each_with_index do |field,index|
        field.each do |k,v|
          if k =='fieldType'
            res << "credentialFields%5B#{index}%5D.fieldType.typeName=#{CGI::escape v['typeName'].to_s}"
          else
            res << "credentialFields%5B#{index}%5D.#{k}=#{CGI::escape v.to_s}"
          end
        end
      end
      res << "credentialFields.enclosedType=com.yodlee.common.FieldInfoSingle"
      res.join("&")
    end

    def add_account(cobSessionToken,userSessionToken,siteId,form)
      parameters = form_to_params(cobSessionToken,userSessionToken,siteId,form)

      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_ADD_SITE_ACCOUNT"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      res = http.post(uri.request_uri, parameters)
      json = JSON.parse(res.body)
      @response=json
    end
  end
    
  class AccountSummary
    attr_reader :response, :error
    def load(cobSessionToken,userSessionToken)
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_ACCOUNT_SUMMARY"])
      params = { :cobSessionToken => cobSessionToken, :userSessionToken => userSessionToken }
      uri.query = URI.encode_www_form(params)
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests
      #This should be POST and a JSON response, like all other calls. - but it's GET and XML.  
      res = http.get(uri)
      begin

        parser = Nori.new
        hash = parser.parse(res.body)
        @response = hash
      rescue
        @error=res.body
      end
      # @error = json['Error']
      @error.nil? ? true : false
    end

    def basics
      # this should be clean json data- but we're working with parsed XML on this method.
      res = []
      @response["ns3:ItemAccountSummaries"]["ns3:ItemContainer"].each do |container|
        container_name = container.first.first
        container[container_name].each do |account|
          res << {
            :type => container_name[4..100],  #remove xml namespacing - hackish.
            :name => account["AccountName"],
            :itemId => account["itemId"],
            :itemAccountId => account["itemAccountId"]
          }
        end
      end
      return res
    end
  end
    
  class ItemSummaries
    attr_reader :response, :error
    def load(cobSessionToken,userSessionToken)
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_GET_ITEM_SUMMARIES"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests
      res = http.post(uri.request_uri,"cobSessionToken=#{cobSessionToken}&userSessionToken=#{userSessionToken}")
      begin
        json = JSON.parse(res.body)
        @response = json
      rescue
        @error=res.body
      end
      # @error = json['Error']
      @error.nil? ? true : false
    end
    def card_txn_test
      self.response.last['itemData']['accounts'].last['cardTransactions'].collect{|t| [t['description'],t['transAmount']['amount'], Date.parse(t['postDate']['date']).to_s]}
    end

    def institution_names
      self.response.collect{ |res| [res['itemId'],res['itemDisplayName']]}
    end

    def institution_data(institution_id)
      self.response.select{|i| i['itemId'] == institution_id}.first
    end

    def account_names(institution_id)
      idata = institution_data(institution_id)
      return [] if idata.nil? || idata.empty?
      idata['itemData']['accounts'].collect{|t| [t['accountId'], t['accountName'], t['accountNumber']]}
    end

    def account_data(institution_id,account_id)
      idata = institution_data(institution_id)
      return [] if idata.nil? || idata.empty?
      idata['itemData']['accounts'].select{|a| a['accountId'] == account_id}.first
    end

    # DEPRECIATED - use get transaction details
    #
    # def card_transactions(institution_id,account_id)
    #   adata = account_data(institution_id,account_id)
    #   return [] if adata.nil? || adata.empty?
    #   adata['cardTransactions']
    # end

    def account_transactions(institution_id,account_id)
      adata = account_data(institution_id,account_id)
      return [] if adata.nil? || adata.empty?
      adata
    end
    
    # DEPRECIATED - use get transaction details
    #
    # def card_transaction_basics(institution_id,account_id)
    #   txns = card_transactions(institution_id,account_id)
    #   txns_out =[]
    #   unless txns.nil? || txns.empty?
    #     txns.each do |txn|
    #       if txn['postDate'].nil? || txn['postDate'].empty? || txn['postDate']['date'].nil? || txn['postDate']['date'].empty?
    #         postdate = nil
    #       else
    #         postdate = Date.parse(txn['postDate']['date'])
    #       end
    #       if txn['transDate'].nil? || txn['transDate'].empty? || txn['transDate']['date'].nil? || txn['transDate']['date'].empty?
    #         txndate = nil
    #       else
    #         txndate = Date.parse(txn['transDate']['date'])
    #       end
    #       amount = txn['transAmount']['amount']
    #       currency = txn['transAmount']['currencyCode']
    #       description = txn['description'].gsub /\b&amp;\b/, "" 
    #       name=description.split(' - ').first.gsub('.',' ').gsub('*',' ').delete('0-9').strip.upcase.squeeze(" ")
    #       #TODO - refactor name parsing above - work in progress!
    #       categories=txn['description'].split(' - ').last.strip.upcase
    #       txns_out << [txn['cardTransactionId'],txndate, postdate,description,name,categories,amount,currency]
    #     end
    #   end
    #   return txns_out
    # end
  end

  class TransactionDetails
    attr_reader :response, :error, :cobSessionToken, :userSessionToken, :searchIdentifier
    def search_request(cobSessionToken,userSessionToken,account_id = nil,start_date = Time.now-(60*60*24*60),end_date = Time.now, options={})

      @cobSessionToken = cobSessionToken
      @userSessionToken = userSessionToken

      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_USER_SEARCH_REQUEST"])

      start_date_str = start_date.strftime('%m-%d-%Y')
      end_date_str = end_date.strftime('%m-%d-%Y')
      url_options ={
        'containerType'                         => (options['containerType']                        || 'All'),
        'higherFetchLimit'                      => (options['higherFetchLimit']                     || 1000),
        'lowerFetchLimit'                       => (options['lowerFetchLimit']                      || 1),
        'resultRange.endNumber'                 => (options['resultRange.endNumber']                || 50),
        'resultRange.startNumber'               => (options['resultRange.startNumber']              || 1),
        'searchClients.clientId'                => (options['searchClients.clientId']               || 1),
        'searchClients.clientName'              => (options['searchClients.clientName']             || 'DataSearchService'),
        'ignoreUserInput'                       => (options['ignureUserInput']                      || 'true'),
        'searchFilter.currencyCode'             => (options['searchFilter.currencyCode']            || 'USD'),
        'searchFilter.postDateRange.fromDate'   => start_date_str,
        'searchFilter.postDateRange.toDate'     => end_date_str,
        'searchFilter.transactionSplitType'     => (options['searchFilter.transactionSplitType']    || 'ALL_TRANSACTION')
      }

      unless account_id.nil?
        url_options['searchFilter.itemAccountId.identifier'] = account_id
      end

      url_string = "cobSessionToken=#{cobSessionToken}&userSessionToken=#{userSessionToken}"

      url_options.each do |k,v|
        url_string += "&transactionSearchRequest.#{k}=#{v}"
      end


      http = Net::HTTP.new(uri.host, uri.port)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests

      res = http.post(uri.request_uri, url_string)
      begin
        json = JSON.parse(res.body)
        @response = json
        @searchIdentifier = @response["searchIdentifier"]["identifier"]
        @txn_count = ''

      rescue
        @error=res.body
      end
      @error.nil? ? true : false
    end

    def additional_txns(startNum, endNum)

      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["sandboxBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_GET_USER_TRANSACTIONS"])
      url_string = "cobSessionToken=#{@cobSessionToken}&userSessionToken=#{@userSessionToken}&searchFetchRequest.searchIdentifier.identifier=#{@searchIdentifier}&searchFetchRequest.searchResultRange.startNumber=#{startNum}&searchFetchRequest.searchResultRange.endNumber=#{endNum}"



      http = Net::HTTP.new(uri.host, uri.port)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      #TODO: DRY up http requests

      res = http.post(uri.request_uri, url_string)
      begin
        json = JSON.parse(res.body)
        @response = json
      rescue
        @error=response.body
      end
      # @error = json['Error']
      @error.nil? ? true : false
    end

    def basics
      res =[]
      @response["searchResult"]["transactions"].each do |txn|
        res << {
          :accountName    => txn['account']['accountName'],
          :accountId      => txn['account']['itemAccountId'],
          :transactionId  => txn['transactionId'],
          :description    => txn['description']['description'],
          :amount         => txn['amount']['amount'],
          :currency       => txn['amount']['currencyCode'],
          :status         => txn['status']['description'],
          :checknumber    => txn['checkNumber'],
          :category       => txn['category']['categoryName']
        }
      end
      return res
    end
  end

end
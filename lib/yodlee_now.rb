require "yodlee_now/version"
require 'uri'
require 'net/ssh'
require 'net/http'
require 'json'

module YodleeNow

  YODLEE_API_URLS = {
    "END_POINT"=>
      {
        "serviceBaseUrl"              =>  "https://rest.developer.yodlee.com/services/srest/restserver/v1.0", 
        "URL_COBRAND_SESSION_TOKEN"   =>  "/authenticate/coblogin", 
        "URL_USER_SESSION_TOKEN"      =>  "/authenticate/login",
        "URL_SEARCH_SITES"            =>  "/jsonsdk/SiteTraversal/searchSite",
        "URL_GET_SITE_LOGIN_FORM"     =>  "/jsonsdk/SiteAccountManagement/getSiteLoginForm",
        "URL_GET_ITEM_SUMMARIES"      =>  "/jsonsdk/DataService/getItemSummaries", 
        "URL_ADD_SITE_ACCOUNT"        =>  "/jsonsdk/SiteAccountManagement/addSiteAccount",
        "foo" => 'bar'
      }
    } 

  class CobrandSession
    attr_reader :response, :sessionToken, :error
    def login(cobrandLogin,cobrandPassword)
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["serviceBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_COBRAND_SESSION_TOKEN"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
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
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["serviceBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_USER_SESSION_TOKEN"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
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
  end

  class ItemSummaries
    attr_reader :response, :error
    def load(cobSessionToken,userSessionToken)
    
      uri = URI.parse(YODLEE_API_URLS["END_POINT"]["serviceBaseUrl"]+YODLEE_API_URLS["END_POINT"]["URL_GET_ITEM_SUMMARIES"])
      http = Net::HTTP.new(uri.host, uri.port)
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      if uri.scheme =='https'
        http.use_ssl = true
      end
      
      res = http.post(uri.request_uri,"cobSessionToken=#{cobSessionToken}&userSessionToken=#{userSessionToken}")
      begin
        json = JSON.parse(res.body)
        @response = json
      rescue
        @error=response.body
      end
      # @error = json['Error']
      @error.nil? ? true : false
    end
    def card_txn_test
      self.response.last['itemData']['accounts'].last['cardTransactions'].collect{|t| [t['description'],t['transAmount']['amount'], Date.parse(t['postDate']['date']).to_s]}
    end
  end

end

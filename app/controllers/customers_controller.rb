class CustomersController < ApplicationController

  
    skip_before_action :verify_authenticity_token
  
    require 'json'
  
    # csrf protection 
    protect_from_forgery with: :reset_session
    # ref : https://guides.rubyonrails.org/security.html#cross-site-request-forgery-csrf
  
    # get - initialize new object for screen display
   
    $initial_phase = 0 
    $entering_data = 1
    $confirm_data = 2   
  
    def register 
   
      @customer = Customer.new
      @message = "Register customer"
      $register_phase = $entering_data 
      session[:birthdate] = ""
      session[:signin] = "" 
      @states = [ "WA" , "CA"]
      @genders = [ "M" , "F" ]
      defaultState = "WA"
      defaultGender = "M"
      @customer.custState = defaultState
      @customer.custGender = defaultGender
  
    end
   
  
    # post edit and save customer record to database
    def registercustomer
    
      @states = [ "WA" , "CA"]
      @genders = [ "M" , "F" ]
      
      # copy screen data to customer object 
      @customer = Customer.new()    

      @custId = params[:customer][:custId].strip
      @custPassword = params[:customer][:custPassword]
      @Encrypted = params[:customer][:Encrypted]
      @custFirst = params[:customer][:custFirst]
      @custLast = params[:customer][:custLast]
      @custMiddle = params[:customer][:custMiddle]
      @custAddr1 = params[:customer][:custAddr1]
      @custAddr2 = params[:customer][:custAddr2]
      @custCity = params[:customer][:custCity]
      @custState = params[:customer][:custState]
      @custZip = params[:customer][:custZip]
      @custGender = params[:customer][:custGender]
      @custEmail = params[:customer][:custEmail]
      @custBirthDate = params[:customer][:custBirthDate]
      @custPhone = params[:customer][:custPhone]
      @custPromo = params[:customer][:PromotionCode]

      @customer.custId = @custId
      @customer.custPassword = @custPassword
      @customer.Encrypted = @Encrypted

      @customer.custFirst = @custFirst
      @customer.custLast = @custLast
      @customer.custMiddle = @custMiddle
      @customer.custAddr1 = @custAddr1
      @customer.custAddr2 = @custAddr2
      @customer.custCity = @custCity
      @customer.custState = @custState
      @customer.custZip = @custZip
      @customer.custGender = @custGender
      @customer.custEmail = @custEmail 
      @customer.custPhone = @custPhone
      @customer.PromotionCode = @custPromo 
       

      @message = "" # screen error message reset here.   
      #log("what does the dob show in reg input format? #{@customer.custBirthDate}")
  
       editMessage = "" 
       editMessage = customer_edits(@customer, "register")  
       if editMessage != ""   
           @message = editMessage     
           render :register
           return
       end   
 
       custId = @custId
       if ENV["A90UseApiCalls"] == "Yes" then   
            c = CustomerNodeRead(custId) 
            serverDown = session[:serverDown]
            if serverDown == "Yes" then
              # in this case c has status code or rescue error messasge.
              @message = "Server is down. Contact Administrator. Issue: #{c}"
              render :register
              return
            end
       else
            c = Customer.find_by('custId':custId)
       end 
       if c != nil  
          @message = "Duplicate Customer" 
          # screen field is text but cust object uses date formatting
          # so put it back to mmddyy from db format in the cust object.
          @custBirthDate = FormatDateForScreen(@custBirthDate)
          render :register
          return
       end 
 
     
       @customer.Encrypted = ""
       @customer._csrf = ""
       @customer.appId = "A90"
       @customer.claimCount = ""   
       @customer.custPlan = ""
       @customer.custBirthDate = FormatForDB(@custBirthDate) 
       @customer.extendColors = ""
       @customer.Id = 0
       @customer.custPassword = session[:pass] #  get stord password in case not keyed last screen.
  
       @customer.custEmail = @customer.custEmail.to_s.strip
  
       if ENV["A90UseApiCalls"] == "Yes" then  
          result = AddCustomerByNode(@customer)
          good = 'good'
          if result == good then 
            session[:signin] = "yes"
            session[:custId] = @custId
            redirect_to controller: :home, action: :menu 
            return
          else
            # show result message from register
            @message = result 
            render :register
            return
          end
       else
   
       # REGISTER CUSTOMER - SAVE RECORD
  
          if @customer.save 
              session[:signin] = "yes"
              session[:custId] = @custId
              redirect_to controller: :home, action: :menu 
              return
          else
              @message = "Save failed"
              render :register
              return
          end

        end
   
    
    end 

    def FormatDateToDB(date)
       # 2022-01-01T00:00:00
      #log("1 date: #{date}")
      suffix = " 00:00:00"
      output = date + suffix
      #log("2 date: #{output}")
      return date
    end

    def AddCustomerByNode(customer)   

        # token 
        token = session[:A65Token].to_s  
        customer._csrf = token 

        urlPrefix = ENV['A90UrlPrefix']
        apiCustomerRegister = "/register"   # returns token in content.  
       
        sendString = urlPrefix + apiCustomerRegister  
         
        custHash = CreateCustomerHash(customer)   
        customerJson = custHash.to_json   
        # 
        #   'Content-Type': 'application/json', 'charset': 'utf-8' 
        #   
        #
        response = Excon.post(sendString, 
        :body => customerJson,  
        :connect_timeout => 15,  
        :method => "POST", 
        :headers => {  
          "Content-Type" =>  "application/json",
          "Charset" => "UTF-8" })  

          raw = response[:body]
    
          # hash it.
          resp = JSON.parse(raw)

          status = resp['Status']
          message = resp['Message']
 

        # 
        # if status unsuccessful display message 
        good = "good"
        if status != "Successful" # 
            if message == nil then
              message = "Registration failed #{message}."
            end
            return message
        end 

        # store token for updates.  
        tokenString = resp['Token']  
        tokenObject = JSON.parse(tokenString) 
        a45object = tokenObject['A45Object']
        token = a45object['token'] 
        session[:A65Token] = token  
        # email edit pattern 
        epattern = resp['EmailPattern'] 
        session[:ePattern] = epattern
         
        return good 

    end

    def AddCustomerByApi(customer)
  
      # post
      # api/Customer
      # 
      urlPrefix = ENV['A90UrlPrefix']
      apiCustomerAdd = "/api/PostCustomer70/"   # returns token in content.  
      custHash = CreateCustomerHash(customer) 
      # 
      customerJson = custHash.to_json 
      sendString = urlPrefix + apiCustomerAdd
      #   'Content-Type': 'application/json', 'charset': 'utf-8' 
      #   
      begin
        response = Excon.post(sendString,  
          :body => customerJson, 
          :headers => {  "Content-Type" =>  "application/json",
                         "Charset" => "UTF-8" })  
      rescue => e 
        @message = "Timeout - Unable to add customer."
        render :signin 
        return
      end
      # 
      # 
      if response.status == 200 # good add  
         session["A65Token"] = response # register gives token 
         return true
      else 
         return false
      end 
    end

    def CreateCustomerHash(customer)
 
      customer.appId = "A90"
      customer.claimCount = "0"
      customer.extendColors = "" 

      custHash = Hash[ "custId" => customer.custId ,
                       "custFirst" => customer.custFirst,
                       "custLast"  => customer.custLast,
                       "custMiddle" => customer.custMiddle,
                       "custGender" => customer.custGender,
                       "custBirthDate" => customer.custBirthDate,
                       "custAddr1" => customer.custAddr1,
                       "custAddr2" => customer.custAddr2,
                       "custCity" => customer.custCity,
                       "custState" => customer.custState,
                       "custZip" => customer.custZip,
                       "PromotionCode" => customer.PromotionCode,
                       "custPass" => customer.custPassword,
                       "Encrypted" => customer.Encrypted, 
                       "custPhone" => customer.custPhone,
                       "custEmail" => customer.custEmail,
                       "custPlan" => customer.custPlan,
                       "extendColors" => customer.extendColors,
                       "appId" => customer.appId,
                       "claimCount" => customer.claimCount]

        return custHash

    end
 
  
  
    def update  
  
      if notSignedIn() then
         render :notauthorized
         return
      end  
  
      @states = [ "WA" , "CA"]
      @genders = [ "M" , "F" ]
      defaultState = "WA"
      defaultGender = "M" 
  
      currentCustomer = session[:custId]   

      if ENV["A90UseApiCalls"] == "Yes" then  
        @customer = CustomerNodeRead(currentCustomer) 
      else
        @customer = Customer.find_by! custId:currentCustomer
      end 
  
      if @customer == nil  
         message = "(update) find by faile loading update screen using custId: #{currentCustomer}"
         render :update
         return
      end  
  
      # copy back to screen for next display. 
      @custId = @customer.custId.strip # hidden field 
      @custFirst = @customer.custFirst.strip
      @custMiddle = @customer.custMiddle.strip
      @custLast = @customer.custLast.strip 
      @custBirthDate = @customer.custBirthDate
      @custAddr1 = @customer.custAddr1.strip
      @custAddr2 = @customer.custAddr2.strip
      @custGender = @customer.custGender.strip 
      @custEmail = @customer.custEmail.strip 
      @custPhone = @customer.custPhone.strip
      @custCity = @customer.custCity.strip
      @custState = @customer.custState.strip
      @custZip = @customer.custZip.strip 
      @password = ""
      @confirm =  ""
      @custBirthDate = FormatDateForScreen(@customer.custBirthDate)
      #@custPromo = @customer.PromotionCode.strip   
      @custPromo = "" # not used 
      @custPlan = @customer.custPlan.strip # display only. 
      @message = "Update Customer"  
      session[:birthdate] = ""    
      render :update 
  
    end
  
    def processupdate  
    
         @states = [ "WA" , "CA"]
         @genders = [ "M" , "F" ]
         defaultState = "WA"
         defaultGender = "M" 
         @message = "" # screen error message reset here.  


        if ENV["A90UseApiCalls"] == "Yes" then  
             
          # get screen into @customer...

          @customer = buildCustomer()
      
        else 
           
          @customer = Customer(customer_params)  
          
        end 

          # copy back to screen for next display. 
        @custId = @customer.custId.strip
        @custFirst = @customer.custFirst.strip
        @custMiddle = @customer.custMiddle.strip 
  
        @custLast = @customer.custLast 
        @custBirthDate = @customer.custBirthDate
        @custAddr1 = @customer.custAddr1
        @custAddr2 = @customer.custAddr2
        @custGender = @customer.custGender 
        @custEmail = @customer.custEmail 
        @custPhone = @customer.custPhone
        @custCity = @customer.custCity
        @custState = @customer.custState
        @custZip = @customer.custZip 
        @password = @customer.custPassword
        @confirm = @customer.Encrypted
        @custPromo = @customer.PromotionCode   
        @custPlan = @customer.custPlan   
  
  
        if @customer == nil 
          message = "(processupdate) : find by faile loading update screen."
          render :update
          return
        end   
 
       
        @goodEditMessage =  EditTheUpdatingCustomer(@customer)
        if @goodEditMessage != nil && @goodEditMessage != ""    
           log("Update edit error: /#{@goodEditMessage}/")
           @message = @goodEditMessage  
           render :update
           return
        end  
      
        custId = @custId



        if ENV["A90UseApiCalls"] == "Yes" then   
           c = CustomerNodeRead(custId) 
        else
           c = Customer.find_by('custId':custId)
        end
 
  
        @password = session[:pass]
        if @password == nil || @password == "" then
           # not entered ? use existing password.
           @password = c.custPassword.strip
        end
        @customer.custPassword = @password
  
        plan = c.custPlan.to_s 
        # if plan not set yet put space in.
        if plan == nil || plan == "" then
           @customer.custPlan = ""
        else
          @customer.custPlan = plan.strip
        end 
  
        # import copy the 'id' field to the output object from input.
        @customer.Id = c.Id 
        #log("** input existing customer seg id is :  #{@customer.Id}.")

        # format birth date 
        @customer.custBirthDate = FormatForDB(@custBirthDate)  
  
        if ENV["A90UseApiCalls"] == "Yes" then   
             successful = UpdateCustomerByNode(@customer)
             if successful == true  # good update
                @message = "Customer Update successful."
                redirect_to controller: :home, action: :menu 
                return
           else
                @message = "Update failed"
                render :update 
                return
           end  
        end
  
        # workaround remove existing record
        # find and delete all customes matching key. 
        custId = @custId
        Customer.destroy_by(custId: custId)   
   
  
        begin
  
        if @customer.update(@custHash) then
        
        #if @cust.update(update_params) then
        
           session[:custId] = custId # was loosing this.   
           s = session[:signin] 
           # note: custId remained intact so only signin had to be reset
           if s == nil then
             log "Customer Update : TC01: Temporary  Correction (not a fix yet ): patch setting signin to yes." 
             session[:signin] = "yes" 
           end
           redirect_to controller: :home, action: :menu 
           return
        else
           log("update fails")
           @message = "Update failed"
           render :update 
           return
        end   
  
      rescue => e 
  
        logerr("reacue: update action issued exception caught here ")
        logerr("program was able to continue with out issues ")
        logerr("noted exception is:")
        logerr(e)
        logerr("--------------------------------")
  
      end 
      
    end

    def buildCustomer() 
      
        # get screen variables into @customer by
        # calling this method.

        cust = Customer.new
 
        cust.custId = params['customer']['custId']
        cust.custPassword = params['customer']['custPassword']
        cust.Encrypted = params['customer']['Encrypted'] 

        cust.custFirst = params['customer']['custFirst']
        cust.custMiddle = params['customer']['custMiddle']
        cust.custLast = params['customer']['custLast'] 

        cust.custGender = params['customer']['custGender']
        cust.custPhone = params['customer']['custPhone']
        cust.custEmail = params['customer']['custEmail']

        cust.custAddr1 = params['customer']['custAddr1']
        cust.custAddr2 = params['customer']['custAddr2']

        cust.custCity = params['customer']['custCity']
        cust.custState = params['customer']['custState']
        cust.custZip = params['customer']['custZip']

        cust.custBirthDate = params['customer']['custBirthDate']
  
        cust.PromotionCode = params['customer']['custPromo']
        cust.custPlan = params['customer']['custPlan']

        return cust

    end
  
    def FormatDateForScreen(input)
      
      log("FormatDateForScreen input is : #{input}.")
      if input == nil  
         local = Date.new(2022,01,02)
         return local
      end
      # copy of update code when loading screen that works!
      birth = input.to_s 
      d = birth[8,2].to_i
      m = birth[5,2].to_i
      y = birth[0,4].to_i 
      localCustBirthDate = Date.new(y,m,d)  
      return localCustBirthDate
    end
  
    
    def EditTheUpdatingCustomer(customer)
   
      message = customer_edits(customer, "update")
      return message
  
    end
    
  
    def UpdateCustomerByNode(customer)


      customer.appId = "A90"
      customer.claimCount = "0"
      customer.extendColors = "" 
      

      # token 
      token = session[:A65Token].to_s  
      customer._csrf = token 

      #  non hash method first 
      json = customer.to_json 
       

      # 
      urlPrefix = ENV['A90UrlPrefix'].to_s 
      apiCustomerUpdate = "/update"  
      # 
      #
      # may need a token ...
      # one last thing.... add the token to the header!
      # 
      sendString = urlPrefix + apiCustomerUpdate  
      customerJSON = customer.to_json   
      # 
      #   'Content-Type': 'application/json', 'charset': 'utf-8' 
      # 

      response = Excon.put(sendString, 
      :body => json,  
      :connect_timeout => 15,  
      :method => "PUT",
      :headers => {  
        "Content-Type" =>  "application/json",
        "Charset" => "UTF-8" })  

       
      status = response.status 
      # 

      if status == 200 # good update 
          return true
      else 
          return false
      end  

    end


 
  
  
    def log(value) 
  
      # comment this out in production 
      require 'logger'
  
      logger.debug(value)
  
    end
  
    
    def logerr(value) 
  
      # comment this out in production 
      require 'logger'
  
      logger.debug("log error: " + value)
  
    end
  
    def customer_edits(customer, screen)
  
      # use this for edit and update add 2nd parmeter to signify which for logic changes
  
      # todo: add space to regex \s did not work
      # sue pub missing text in book
      # copy regex file back and fix date edit
      # save password so not rekey annoy  

      message = ""
      
      standard = Regexp.new("^[\s.a-zA-Z0-9]+$") 
      standard_or_space= Regexp.new("^[\s.a-zA-Z0-9]*$")  
  
      standard2 = Regexp.new("^[a-zA-Z0-9.\\s]*$") # 60 uses this.
  
      if screen == "register"
          editMessages = Array.new 
          if standard !~ customer.custId  
             message = "Please enter a valid customer Id with letters or numbers."
             return message
           end
      end    
        
      # rails loosing :pass from session force password keying on register
      # and have a seperate password screen.
  
      check = session[:pass]
      if check == nil || check == "" then
          #log("set pass to none") 
          storedPassword = "none"
      else
        storedPassword = session[:pass]
      end  

      passwordEntered  = customer.custPassword != nil && customer.custPassword != ""  
      #log("password entered #{passwordEntered}.")
      #log("customer password is #{customer.custPassword}.")
      if passwordEntered == true then 
            if customer.custPassword !~ standard
              message = "Password must be numeric or letters "
              return message
            end  
            # confirm check - message not in model so confrim is not either ! 
            if customer.custPassword != customer.Encrypted 
              message = "Password and confirmation password do not match." 
              return message
            end 
    
            #log "setting stored password to #{customer.custPassword}."
            #log("stored")
            session[:pass] = customer.custPassword
            # register - uses sesson[:pass]
            # update - uses session[:pass] if entered; else use existing pw from customer.
        else
            # no password entered on register screen and none saved - prompt user.
            if screen == "register" and storedPassword == "none"  
            then
              message = "Password is required for registration." 
              return message
            end
        end   
     
        postcheck = session[:pass] 
  
  
    if standard2 !~ customer.custFirst  || customer.custFirst.strip == ""
      message = "Please enter a valid customer first name  with letters or numbers." 
      return message
   end
   if standard_or_space !~ customer.custMiddle  
     message = "Please enter a valid customer middle name  with letters or numbers." 
     return message
  end
   if standard2 !~ customer.custLast || customer.custLast.strip == ""
     message = "Please enter a valid customer last name  with letters or numbers." 
     return message
  end
  
  if standard !~ customer.custAddr1  || customer.custAddr1.strip == ""
    message = "Please enter a valid customer address 1  with letters or numbers." 
    return message
  end
  
  if standard_or_space !~ customer.custAddr2 
    message = "Please enter a valid customer address 2 or leave blank." 
    return message
  end
  
  customer.custGender = customer.custGender.upcase
  unless customer.custGender == "M" || customer.custGender == "F"   
    message = "Gender must be M or F." 
    return message
  end
  
  
  if standard !~ customer.custCity  || customer.custCity.strip == ""
    message = "Please enter a valid customer city  with letters or numbers." 
    return message
  end 
  
  if standard !~ customer.custState || customer.custState.strip == ""
    message = "Please enter a valid customer state  with letters or numbers." 
    return message
  end 
  
  customer.custState = customer.custState.upcase
  if customer.custState != "WA" && customer.custState != "CA"
    message = "Please enter a valid state code. " 
    return message
  end 
  
  if standard !~ customer.custZip  || customer.custZip.strip == ""
    message = "Please enter a valid customer zip code  with letters or numbers." 
    return message
  end
  
  # email and telephone edits
  
  # emailpattern = Regexp.new("[a-z0-9A-Z]+@[a-z0-9A-Z].[a-z0-9A-Z]")

  # from A45 environment variable.
  emailpattern =  session[:ePattern].to_s
 
  eRegexpPattern = Regexp.new emailpattern
  if eRegexpPattern !~ customer.custEmail 
    message = "Please enter a valid customer email" 
    return message
  end
   
  phonePattern = Regexp.new("[0-9]{10}")
  if phonePattern !~ customer.custPhone
    message = "Please enter a valid phone number all numeric no punctuation." 
    return message
  end
   
  envPromoCode = ENV["A90PromotionCode"]
  if screen == "register"
    # prmo code edit
      # **** todo read promo from environment 
        if customer.PromotionCode !=  envPromoCode 
          message = "invalid promotion code" 
          return message
        end  
  else
       customer.PromotionCode = envPromoCode  # default on update screen.  
  end
    
   #log("birth date into cust edits is #{@custBirthDate}")
  
   if @custBirthDate == nil 
      message = "Please select a birth date."
      return message
   end
    
   # note: used for both register and update
   rangeMessage = DateRangeCheckForBirthAndService(@custBirthDate, screen , "Birth Date")
   if rangeMessage != "" 
      message = rangeMessage
      return message
   end 
  
    
   # duplicate and existence check 
   # find:
   # 0 - good new customer
   # 1 - duplicalte error
   # > 1 - duplicate record error
  
    if screen == "register_fix_this"
       
        customerCount= 0 
  
        customerArray =  Customer.all.select do |m| 
           value = m.custId.strip 
  
           if value == customer.custId then
              customerCount = customerCount + 1
           end
        end 
         
        if customerCount == 1
          message = "Customer already exists." 
          return message
        end
  
        if customerCount > 1
          message = "#{customerCount} Duplicate Customer Records found."
          return message
        end
  
    end 
    
  
    good_result = ""
    return good_result 
  
    end
  
    
    def signin
          
      @message = "Enter Customer Id and Password to sign in." 
  
  end

  def FormatForDB(inputDate)

      # format is yyyy-mm-dd from the control.
      iy = inputDate[0..3]
      im = inputDate[5..6]
      id = inputDate[8..9] 
      dash = "-"

      # add time suffix.
      dbDate = iy + dash + im + dash + id 
      return dbDate

  end
  
  def DateRangeCheckForBirthAndService(inputDate, screen, which)
      
      message = "" 
   
      # service date within 1 year; screen = claim. 

      if inputDate == "" then
         message = "#{which} is invalid."
         return message
      end
  
      # format is yyyy-mm-dd
      iy = inputDate[0..3]
      im = inputDate[5..6]
      id = inputDate[8..9] 

      y = iy.to_i
      m = im.to_i
      d = id.to_i 
      
      # both screens coded as register - register and update.
      if screen == "register"  
  
         # no future dates  
         # with in 115 years in the past
  
         # adjust yy to yyyy
         # add case for yyyy input here.
  
         max_age = 115
  
         currentYear =  Time.current.year()
         currentMonth = Time.current.month()
         currentDay = Time.current.day()
  
         if y > currentYear ||
            (y == currentYear && m > currentMonth) ||
            (y == currentYear && m == currentMonth && d > currentDay)
         then
            message = "Future birth dates are not valid."
            return message
         end 
  
         if (currentYear - y) > max_age 
            message = "Entered date over #{max_age} years in past. Year was #{y}."
            return message
         end
  
         return ""
  
  
      end
  
  
  end
   
  
  def signincustomer 
    
    custId = params[:custId]
    pass = params[:custPassword] 
  
    if custId == "" then 
       @message = "Please enter a customer Id." 
       return
    end
 
    if pass == "" then 
       @message = "Please enter a valid password."
       render :signin, status: :unprocessable_entity
       return
   end
  
   standard = Regexp.new(/[a-zA-Z0-9]+/) 
  
   # scrub using reg ex ruby syntax 
   bad = "Invalid characters in customer alpha numeric only."
   if standard =~ custId then
   else     
      @message = bad
      render :signin, status: :unprocessable_entity 
      return
   end
  
   bad2 = "Invalid characters in password alpha numeric only."
   if standard =~ pass then
   else 
      @message = bad2
      render :signin, status: :unprocessable_entity
      return
   end 
  
   #puts " standard db call for signin"
  
   if ENV["A90UseApiCalls"] == "Yes" then  
        ## c = CustomerSigninByApi(custId, pass)
        c = CustomerSigninByNode(custId, pass)
        # if it returns here the server is down with status or error code.
        serverDown = session[:serverDown]
        if serverDown == "Yes" then
          # in this case c has status code or rescue error messasge.
          @message = "Server is down. Contact Administrator. Issue: #{c}"
          render :signin
        end
        return 
    end
  
  # database access call  - uses id as default. use custId in expression. 
    # existence check  
    not_there = nil 
    existing = Customer.find_by(custId: custId)   
  
    #message = "#{customer.custId}   existing:     #{existing}" 
    if existing == not_there then
      @message = "Customer not found. Please register."
      render :signin, status: :unprocessable_entity
      return
    end 
  
    # check for duplicates only with standard db call. not api call.
    customerResultSet = Customer.where(custId: custId).first(2)
    if customerResultSet.length == 2 then
      @message = "Duplicate Customers"
      render :signin, status: :unprocessable_entity
      return
    end  
  
    # add a password check
    custPass = ""
    work = ""
    customerResultSet.each do |cust| 
      work = cust.custPassword
    end
    custPass = work.strip 
    if custPass != pass 
      @message = "Password is not correct."
      render :signin, status: :unprocessable_entity
      return
    end 
     
  
    session[:signin] = "yes"
    session[:custId] = custId 
  
    check = session[:custId]
    log  " this is signin custId in session is valued at: #{check}."
    redirect_to controller: :home, action:  :menu
     
   return
  
  end 
 
  def CustomerNodeRead(custId)

    
    urlPrefix = ENV['A90UrlPrefix']
    apiSigninReadUrl = "/cust?id=" + custId.strip
    actionString = urlPrefix + apiSigninReadUrl 

    session[:serverDown] = "No" 
    begin 
      connection = Excon.new(actionString, :connect_timeout => 15) 
      response = connection.get 
    
    rescue => error 
        session[:serverDown] = "Yes"
        return "error: #{error.class} #{error.message}" 
    end
 

     # hash  @data = { :body => ...}
     raw = response[:body]  
 

     # hash it.
     resp = JSON.parse(raw)

     status = resp['Status']
     message = resp['Message'] 
     token = resp['Token']
     custHash = resp['Customer']
 

     if status == "Successful" then
        customer = customerHashToObject(custHash)
        return customer
     end

     if status == "Unsuccessful" then
        if message.index("not found") != nil then 
          return nil
        end
      end
 

    # return 'not found' or error messasge.
    session[:serverDown] = "Yes"
    return message 

  end

  def CustomerApiRead(custId)

    urlPrefix = ENV['A90UrlPrefix']
    apiSigninReadUrl = "/api/customer/" + custId.strip
    actionString = urlPrefix + apiSigninReadUrl
    session[:serverDown] = "No"
 
    # TODO: add time out logic here by rescue xxx
    # @message = "Timeout - Unable to read customer with error code."
    #render :signin 
    # return

    begin 
      connection = Excon.new(actionString, :connect_timeout => 15 ) 
      response = connection.get 
    
    rescue => error 
        session[:serverDown] = "Yes"
        return "error: #{error.class} #{error.message}" 
    end
    #log "customer api read status: #{response.status}." 
    if response.status == 404  # not found
       return nil
    end
    if response.status == 200
      cust = response.body  
      custHash = JSON.parse(cust) # create hash 
      customer = customerHashToObject(custHash)  
      #Id = customer.Id   
      return customer
    end
 
    session[:serverDown] = "Yes"
    return "status: #{response.status}"  

  end

  def customerHashToObject(h)

      c = Customer.new

      # do not use openstruct
      c.Id = h['id']
      c.custId = h['custId']
      c.custPassword = h['custPassword']
      c.Encrypted = h['Encrypted']
      c.custFirst = h['custFirst']
      c.custMiddle = h['custMiddle']
      c.custLast = h['custLast']
      c.custGender = h['custGender']
      c.custPhone = h['custPhone']
      c.custEmail = h['custEmail']
      c.custAddr1 = h['custAddr1']
      c.custAddr2 = h['custAddr2']
      c.custCity = h['custCity']
      c.custState = h['custState']
      c.custZip = h['custZip']
      c.custBirthDate = h['custBirthDate']
      c.custPlan = h['custPlan']
      c.PromotionCode = h['PromotionCode']
  
      
      return c

  end

  def CustomerSigninByNode(custId, password)

      not_found = "Customer not found."
      session[:serverDown] = "No"
      urlPrefix = ENV['A90UrlPrefix']
      #   
      a = "/signin?id=" + custId + "&pw=" + password; 
      signinString = urlPrefix + a
    
      #
      begin 
          connection = Excon.new(signinString, :connect_timeout => 15) 
          response = connection.get 
      rescue => e 
          session[:serverDown] = "Yes"
          item  = "message: #{e.class} #{e.message}"
          #log("1. signin 70 rescue #{item}")
          return item
      end  
      # a45 returns null for 500 .
      if response == nil then
        session[:serverDown] = "Yes"
        item  = "message: nothing returned server down..." 
        return item
      end

      # hash  @data = { :body => ...}
      raw = response[:body]  
 

      # hash it.
      resp = JSON.parse(raw)

      status = resp['Status']
      message = resp['Message']  
      customer = resp['Customer'] 
      ePattern = resp['EmailPattern']

      # save for update edit.
      session[:ePattern] = ePattern
 

      # password check is handled here also.
      if status == "Unsuccessful" then
         if message.index(not_found) != nil then
            @message = "Customer not found."
            render :signin 
            return
         end
         if message.index("Password") != nil then
            @message = message
            render :signin 
            return 
         end
         @message = "unknown error"
         render :signin
         return
      end  

      # store token for updates.  
      tokenString = resp['Token']  
      tokenObject = JSON.parse(tokenString) 
      a45object = tokenObject['A45Object']
      token = a45object['token'] 
      session[:A65Token] = token  
      
      session[:signin] = "yes"
      session[:custId] = custId    
        
      redirect_to controller: :home, action:  :menu


  end
 
  def CustomerSigninByApi(custId, password)
   
     session[:serverDown] = "No"
     urlPrefix = ENV['A90UrlPrefix']
     # encrypted field  gets the token!!! 
     apiSigninReadUrl = "/api/Signin70/" + custId
     signinString = urlPrefix + apiSigninReadUrl

  
     #
     begin 
         connection = Excon.new(signinString, :connect_timeout => 15 ) 
         response = connection.get 
     rescue => e 
         session[:serverDown] = "Yes"
         item  = "message: #{e.class} #{e.message}"
         #log("1. signin 70 rescue #{item}")
         return item
     end
 
        
     if response.status != 200  # not good read 

          if response.status = 404 # not found 
              @message = "Customer not found:#{signinString}."
              render :signin 
              return
          end 
          session[:serverDown] = "Yes" 
          item  = "signin 70 status - status : #{response.status}"
          log(item)
          return item

    end 
 

     cust = response.body   
     customer = JSON.parse(cust) # create hash  

     # store token for updates.
     token = customer["encrypted"]  
     session[:A65Token] = token 

     custId  = customer['custId']
     work = customer['custPassword'] 
     customerPassword = work.strip() 
 
     if password != nil &&  password != customerPassword 
      @message = "Invalid password for customer"
      render :signin 
      return
     end  
     
    session[:signin] = "yes"
    session[:custId] = custId 
  
    #check = session[:custId]
    #puts  " this is signin custId in session is valued at: #{check}."
    redirect_to controller: :home, action:  :menu
  
  end
  
  def notSignedIn
  
     # prevent unauthorized access
     checkForYes = session[:signin]
     if checkForYes == "yes" then
        return false 
     end  
     return true
    end
  
  def signout
      
  
    begin 
       session[:signin] = ""
       session[:custid] = ""  
       redirect_to controller: :home, action:  :start
       return  
    rescue 
       puts 'signout had issue'
    end
  
  end
  
  # ====================== section two == plan claim history ==============================
  
  def plan  
      
      if notSignedIn() then
         render :notauthorized
         return
      end
  
      begin
  
      # form submit logic 
      if request.method == "POST" then    
         #check = session[:custId]
         #puts "this is plan POST custId is from session as: #{check}." 
         planName = params[:commit]  
         #puts "this is plan POST planName from submit button is .#{planName}."
         if planName == "Cancel" then
            flash[:message] = "Plan change cancelled."
            redirect_to controller: :home, action:  :menu
            return
         end
         #puts " plan name from submit button is #{planName}."
         custId = session[:custId]  
         #puts " cust id no longer HARDCODED to 1 but is now #{custId}."
         if ENV["A90UseApiCalls"] == "Yes" then  
             UpdateCustomerPlanNode(custId, planName)
         else
             @customer = Customer.find_by(custId: custId)
             @customer.update(custPlan: planName) 
         end
         flash[:message] = "Successful plan update for customer #{custId} to plan #{planName}."
         redirect_to controller: :home, action:  :menu
         return
      end
      
      if ENV["A90UseApiCalls"] == "Yes" then 
           @plans = GetPlansNode()
      else
      # initial screen logic.
           @plans = Plan.all 
      end
      check = session[:custId]
      #puts "this is plan GET before screen load custId is found to be in session as #{check}."
   
  
    rescue Exception => ex 
  
      @message = "Exception occurred in Plan routine: #{ex}."
      render :plan
      return
  
    end
  end

  def UpdateCustomerPlanNode(custId, planName)

      cus = custId.strip
      name = planName.strip 
      # 
      urlPrefix = ENV['A90UrlPrefix']
      apiCustomerPlanUpdate = "/updatePlan"   

      # for A45 server use json and check return status = 200 
      sendString = urlPrefix + apiCustomerPlanUpdate 
      token = session["A65Token"] 

       #   'Content-Type': 'application/json', 'charset': 'utf-8'  
       #  
       parm = Hash[ "CustPlan" => name, "CustId" => custId, "_csrf" => token] 
       json = parm.to_json  

       log 'update plan'
       log sendString
       log json

       begin
        response = Excon.put(sendString,  
          :body => json,  
          :headers => {  "A65TOKEN" => token,
                         "Content-Type" =>  "application/json",
                         "Charset" => "UTF-8" }) 
      rescue => e
         
         log("1/ update customer plan excon status code recieved: #{response.status}")
         log("update plan  send error : #{e.class} #{e.message}.")
         return false
      end
      # 
      # 
      if response == "OK" # good update 
         return true
      else 
         return false
      end  

  end
 

  def GetPlansNode

      urlPrefix = ENV['A90UrlPrefix']
      readPlans = '/readPlans' 
      actionString = urlPrefix + readPlans

      begin 
        connection = Excon.new(actionString, :connect_timeout => 15) 
        response = connection.get 
      rescue => e 
          log("excon cust read plans error...")
          return nil
      end

      good = 200
      if response.status == good then
         planList = response.body
         planHash = JSON.parse(planList) # create hash   
         return planHash
      end 
      msg = "read plan error #{response.status}"
      log msg
      return nil
      
  end
   
 
  
  
  # ===================== private area ====================================================
   
    private 
  
    def customer_params
  
      params.require(:customer)
            .permit(:custId, :custPassword, :Encrypted, :custFirst,
                    :custLast, :custBirthDate,:custMiddle,:custAddr1,:custAddr2, 
                    :custCity, :custState, :custZip, :PromotionCode,
                    :custPhone,  :custGender, :custEmail, :custPromotonCode)
  
    end
  
     
    end
  
    
    def update_params
  
      params.require(:customer)
            .permit(:custId, :custPassword, :Encrypted, :custFirst,
                    :custLast, :custBirthDate,:custMiddle,:custAddr1,:custAddr2, 
                    :custCity, :custState, :custZip, :PromotionCode, :custBirthDate,
                    :custPhone,  :custGender, :custEmail, :custPromotonCode, :custPlan)
  
    end
  
    def signin_params
  
      params.permit(:custId, :custPassword) 
  
    end
  
    # todo ---- add claims params.
   
   
  
   
  

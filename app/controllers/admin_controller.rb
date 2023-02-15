class AdminController < ApplicationController

    def admin 
    end

    def adminsignin

        admId = params[:admId]
        pass = params[:admPassword] 
      
        if admId == "" then 
           @message = "Please enter a administrator Id."
           render :admin, status: :unprocessable_entity
           return
        end
     
        if pass == "" then 
           @message = "Please enter a valid password."
           render :admin, status: :unprocessable_entity
           return
       end
      
       standard = Regexp.new(/[a-zA-Z0-9]+/) 

         # scrub using reg ex ruby syntax 
        bad = "Invalid characters in administrator id alpha numeric only."
        if standard =~ admId then
        else     
            @message = bad
            render :admin, status: :unprocessable_entity 
            return
        end
        
        bad2 = "Invalid characters in password alpha numeric only."
        if standard =~ pass then
        else 
            @message = bad2
            render :admin, status: :unprocessable_entity
            return
        end 

       envId = ENV['A90AdmId']
       envPass = ENV['A90AdmPass']
        
       if envId != admId then 
           @message = "Administrator Id is incorrect"
           render :admin, status: :unprocessable_entity 
           return
       end

       if envPass != pass then 
           @message = "Administrator password is incorrect"
           render :admin, status: :unprocessable_entity 
           return
       end 

       # edits redundant - get token.

       urlPrefix = ENV['A90UrlPrefix']
       # encrypted field  gets the token!!! 
       apiSigninReadUrl = "/adminSignin?id=#{admId}&pw=#{pass}"
       adminString = urlPrefix + apiSigninReadUrl
    
       #
       begin 
           connection = Excon.new(adminString, :connect_timeout => 15) 
           response = connection.get 
       rescue => e  
           item  = "Error : does new customer exist - message: #{e.class} #{e.message}" 
           return item 
       end

       raw = response[:body]  
       resp = JSON.parse(raw)
       status = resp['Status']
       message = resp['Message']
       tokenString = resp['Token'] 
       tokenObject = JSON.parse(tokenString) 
       a45object = tokenObject['A45Object']
       token = a45object['token'] 
       session[:A65Token] = token  

       #log '--- admin signin ---'
       #log 'status'
       #log status
       #log 'message'
       #log message
       #log 'token'
       #log token.to_s

       if status == "Unsuccessful" then
           @message = message 
           render :admin, status: :unprocessable_entity 
           return
       end

       session['A65Token'] = token 
       
       redirect_to controller: :admin, action: :action 

    end

    def action  
    end

    def actionresponse

        # scrub all fields 
        
        standard = Regexp.new("^[\s.a-zA-Z0-9]*$")  

        custId = params[:custId]   
        if standard !~ custId then  
            @message = "Invalid characters in customer id alpha numeric only."
            render :action, status: :unprocessable_entity 
            return
        end 
        
        newId = params[:newId]   
        if standard !~ newId then 
            @message = "Invalid characters in new customer id alpha numeric only."
            render :action, status: :unprocessable_entity 
            return
        end

        custPassword = params[:custPassword]   
        if standard !~ custPassword then 
            @message = "Invalid characters in customer password alpha numeric only."
            render :action, status: :unprocessable_entity 
            return
        end 

        conPassword = params[:conPassword]   
        if standard !~ conPassword then 
            @message = "Invalid characters in confirm password alpha numeric only."
            render :action, status: :unprocessable_entity 
            return
        end 
      
        submitValue = params[:commit]  
    
        if submitValue == "Reset Customer" then 
           if custId == "" then
                @message = "Customer id is blank"
                render :action, status: :unprocessable_entity 
                return 
           end
            if newId == "" then
                @message = "New Customer id is blank"
                render :action, status: :unprocessable_entity 
                return 
            end
            if custId == newId then
                @message = "New Customer id must be differend then the Customer id"
                render :action, status: :unprocessable_entity 
                return 
            end
            # ===========================================
            # a45 does not return status.code so check here
            # until corrected 
            # ==============================================
            # customer to be reset
            result = DoesCustomerExist(custId)
            if result == "notexist" then
                @message = "Customer to be reset does not exist."
                render :action, status: :unprocessable_entity 
                return 
            end 
            # =====================================
            # customer to be reset to 
            result = DoesCustomerExist(newId)
            if result == "exist" then
                @message = "New Customer already exists."
                render :action, status: :unprocessable_entity 
                return 
            end 
            # =====================================
        end
 
         if submitValue == "Reset Password" then 
            if custId == "" then
                @message = "Customer id is blank"
                render :action, status: :unprocessable_entity 
                return 
            end
            if custPassword == "" then
                @message = "Password is blank"
                render :action, status: :unprocessable_entity 
                return 
           end
            if conPassword == "" then
                @message = "Confirm Password id is blank"
                render :action, status: :unprocessable_entity 
                return 
            end
            if custPassword != conPassword  then
                @message = "Password and confirm password do not match"
                render :action, status: :unprocessable_entity 
                return 
            end
         end

         if submitValue == "List Customers" then  
            customerlist()
            return
         end

         if submitValue == "Reset Customer" then 
            resetCustomer(custId, newId)
            return
         end
  
         if submitValue == "Reset Password" then 
             resetPassword(custId, custPassword)
             return
         end
        
    end

    def DoesCustomerExist(custId)
 
        urlPrefix = ENV['A90UrlPrefix']
        # encrypted field  gets the token!!! 
        apiSigninReadUrl = "/cust?id=" + custId
        existString = urlPrefix + apiSigninReadUrl
     
        #
        begin 
            connection = Excon.new(existString, :connect_timeout => 15 ) 
            response = connection.get 
        rescue => e  
            item  = "Error : does new customer exist - message: #{e.class} #{e.message}" 
            return item 
        end

        raw = response[:body]  
 
  
        # hash it.
        resp = JSON.parse(raw)
  
        status = resp['Status']
        message = resp['Message']  
        customer = resp['Customer'] 
  
        # password check is handled here also.
        not_found = "Not Found"
        if status == "Unsuccessful" then
           if message.index(not_found) != nil then
              @message = "Customer not found."
           else
              @message =  "Error occured - does custome exist." 
    
           end
           return "notexist"
        end 

        return "exist" 
     
    end

    def customerListNode  
        
        urlPrefix = ENV['A90UrlPrefix']
        url = "/custlist" 
        actionString = urlPrefix + url   

        begin 

            connection = Excon.new(actionString, :connect_timeout => 15) 
            response = connection.get  

            if response.status == 404
                @message = "No customers found."
                render :action 
                return
            end

            if response.status != 200
                @message = "customer list read error status #{response.status}"  
                render :action 
                return
            end 

        rescue

            @message = "Time out likely server down ....."  
            render :action 
            return
        end 

        customerList = response.body 
        @customerList = Array.new 

        length = customerList.length
        i = 0
        while i < length 
            #customerHash = JSON.parse(customerList[i]) # create hash
            oneCustomer = customerHashToObject(customerList[i])  
            @customerList.push(oneCustomer)  
            i = i + 1
        end 

        # flag last customer 
        oneCustomer = @customerList.pop
        oneCustomer.extendColors = "yes"
        @customerList.push(oneCustomer)
 
        if @customerList == nil then 
             @message = "No Customers found."
             render :action 
             return
         end   
         
         render :customerlist
         return 
  



    end

    def customerlist 
          
        urlPrefix = ENV['A90UrlPrefix']
        url = "/custList" 
        actionString = urlPrefix + url   

        begin 

            connection = Excon.new(actionString, :connect_timeout => 15) 
            response = connection.get  

            if response.status == 404
                @message = "No customers found."
                render :action 
                return
            end

            if response.status != 200
                @message = "customer list read error status #{response.status}"  
                render :action 
                return
            end 

        rescue

            @message = "Time out likely server down ....."  
            render :action 
            return
        end 
 
        raw = response[:body]
        list = JSON.parse(raw) 
  
        @customerList = Array.new
        list.each do | hi | # hash item is 'hi'. 
           oneCustomer = customerHashToObject(hi)  
           @customerList.push(oneCustomer) 
        end 

        # flag last customer 
        oneCustomer = @customerList.pop
        oneCustomer.extendColors = "yes"
        @customerList.push(oneCustomer)
 
        if @customerList == nil then 
             @message = "No Customers found."
             render :action 
             return
         end   
         
         render :customerlist
         return 
  

    end
 

    def customerHashToObject(h) 
        c = Customer.new() 
        c.custId = h['custId']
        c.custFirst = h['custFirst']
        c.custLast = h['custLast']
        c.custPassword = h['custPassword']
        c.appId = h['appID']
        c.extendColors = h['extendColors']
        return c
    end

    def resetCustomer(custId, newId)

        urlPrefix = ENV['A90UrlPrefix']
        apiResetCustomer = "/resetCustomerId"   
        # 
        #
        # may need a token ...
        # one last thing.... add the token to the header!
        #  
        token = session["A65Token"] 
        sendString = urlPrefix + apiResetCustomer 
        #   'Content-Type': 'application/json', 'charset': 'utf-8'  
        #  
        parm = Hash[ "custId" => custId, "newCustId" => newId, "_csrf" => token] 
        json = parm.to_json  
    
        begin
          response = Excon.put(sendString,  
            :body => json,  
            :headers => {  
                           "Content-Type" =>  "application/json",
                           "Charset" => "UTF-8" }) 
        rescue => e
           
           m1 = "reset customer plan excon status code recieved: #{response.status} "
           m2 = "reset customer send error : #{e.class} #{e.message}."
           @message = m1 + m2
           render :action 
           return 
        end
        
        
        if response.status = "200" then
            @message = "Successful customer reset."
        else
            @message = "Customer reset was not successful."
        end
         
        render :action 
        return
    end

    def resetPassword(custId, newPassword)
 

        urlPrefix = ENV['A90UrlPrefix']
        apiResetPassword = "/resetPassword"   
        # 
        #
        # may need a token ...
        # one last thing.... add the token to the header!
        #  
        token = session["A65Token"] 
        sendString = urlPrefix + apiResetPassword 
        #   'Content-Type': 'application/json', 'charset': 'utf-8'  
        #  
        parm = Hash[ "custId" => custId, "newPassword" => newPassword, "_csrf" => token] 
        json = parm.to_json  
        m1 = "" 
        begin
          response = Excon.put(sendString,  
            :body => json,  
            :headers => {  
                           "Content-Type" =>  "application/json",
                           "Charset" => "UTF-8" }) 
        rescue => e
           
           m1 = "password reset excon status code: #{response.status} #{e.class} #{e.message}." 
        end 
         
        if response.status == 200 # good update 
           @message = "Successful password reset."
        else 
           @message = "unsuccessful password reset - status #{response.status}"
        end 
 
        render :action 
        return
    end 

    
    def log(value)
        Rails.logger.info(" log: " + value)
    end

end

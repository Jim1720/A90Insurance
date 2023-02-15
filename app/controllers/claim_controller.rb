class ClaimController < ApplicationController 

    # ====================================================
    # read hidden field on submit so we know claim type.
    #=====================================================
    def ClaimFromScreen() 
      
         # initial screen logic. New Claims.
         claim = Claim.new()

         claim.ClaimType = params[:ClaimTypeLetter].strip 
         claim.PatientFirst = params[:claim]['PatientFirst'].strip  
         claim.PatientLast = params[:claim][:PatientLast].strip 
         claim.ClaimDescription = CheckNullStrip(params[:claim][:ClaimDescription])
         claim.Physician = params[:claim][:Physician]
 
         work = params[:claim][:service]
         claim.Service = work.strip 

         claim.Diagnosis1 = params[:claim][:Diagnosis1].strip
         claim.Diagnosis2 = CheckNullStrip(params[:claim][:Diagnosis2])
         claim.Procedure1 = params[:claim][:Procedure1].strip 
         claim.Procedure2 = CheckNullStrip(params[:claim][:Procedure2]) 
         claim.DateService = params[:claim][:DateService] 
         claim.Referral = CheckNullStrip(params[:claim][:Referral])
         claim.Clinic = CheckNullStrip(params[:claim][:Clinic]) 
         claim.DateConfine = InputValueOrNull(params[:claim][:DateConfine],"")
         claim.DateRelease = InputValueOrNull(params[:claim][:DateRelease],"") 
         claim.ToothNumber = InputValueOrNull(params[:claim][:ToothNumber],"d") 
         claim.Eyeware = InputValueOrNull(params[:claim][:Eyeware],"") 
         claim.DrugName = InputValueOrNull(params[:claim][:DrugName],"")  

         # read values from params. 

         return claim

    end

    def InputValueOrNull(value, type)
        if value == nil && type == "d" then return "0"  end
        if value == nil && type != "d" then return ""   end
        return value
    end

    def EmptyClaim

      claim = Claim.new()


         return claim

   
    end
       
    def claim

  
       turnOff = ""
       session[:promisedIdForAdjorCopy] = turnOff
    
       claimIdToAdjust = session[:adjustClaimId] 
       
       if claimIdToAdjust != nil then
          
          # initial screen logic adjusted claims
    
          # set up adjustment 
          if ENV["A90UseApiCalls"] == "Yes" then   
              @claim = GetClaimByNode(claimIdToAdjust)
          else 
              @claim = Claim.find_by ClaimIdNumber: claimIdToAdjust
          end
  
          # remove trailing blanks 
          if @claim == nil then
             @message = "Warn: unable to find claim to adjust routine:claim: #{claimIdToAdjust}."
             flash[:message] = @message
             redirect_to controller: :home, action:  :menu
             return
         end
  
          @ClaimStatus = CheckNullStrip(@claim.ClaimStatus)
          @PatientFirst = @claim.PatientFirst.strip
          @PatientLast = @claim.PatientLast.strip
          @Procedure1 = @claim.Procedure1.strip
          @Procedure2 = CheckNullStrip(@claim.Procedure2)
          @Diagnosis1 = @claim.Diagnosis1.strip
          @Diagnosis2 = CheckNullStrip(@claim.Diagnosis2)
          @ClaimDescription = @claim.ClaimDescription.strip
          @Physician = @claim.Physician.strip
          @CustomerId = @claim.CustomerId.strip
          @PlanId = @claim.PlanId.strip.strip
          @Service = @claim.Service.strip
          @Clinic =CheckNullStrip(@claim.Clinic)
          @ClaimType = @claim.ClaimType.strip
 

          @DateService = FormatDateForScreen(@claim.DateService)
          @Referral = CheckNullStrip(@claim.Referral)
          @AdjustingClaimId = ""
          @AdjustedClaimId = "" 
          defaultDate = Time.new(1753,1,1)
          @AdjustedDate = defaultDate
          claimType = @claim.ClaimType.strip
  
          if claimType == "m" then   # find default value on input and test it here TODO.
               @DateConfine = FormatDateForScreen(@claim.DateConfine)
               @DateRelease = FormatDateForScreen(@claim.DateRelease) 
         elsif claimType == "d" then
               @ToothNumber = CheckNullStrip(@claim.ToothNumber)
         elsif claimType == "v" then
               @Eyeware = CheckNullStrip(@claim.Eyeware)
         elsif claimType == "x" then
               @DrugName = CheckNullStrip(@claim.DrugName)
         else
            a = 1 
         end
          
    
          # Create new claim id for adjustment - update will need to set fields from/to adj etc.
          currentClaimIdNumber = @claim.ClaimIdNumber
          newAdjustmentClaimIdNumber = assignClaimId()
          
          # Adjusted Claim Id = will signal claim add that this an adjustment 
          @claim.AdjustedClaimId = currentClaimIdNumber
          # rename the claim with new claim id number
          @claim.ClaimIdNumber = newAdjustmentClaimIdNumber 
          session[:promisedIdForAdjorCopy] = newAdjustmentClaimIdNumber
           
          @message = "Enter Data for adjustment #{newAdjustmentClaimIdNumber} adjusting #{currentClaimIdNumber}."
        
          #set service drop down
          claimType = @claim.ClaimType
          lowerCase = claimType.downcase
          @ClaimType = lowerCase
          literal = getTypeLiteral(lowerCase)
          selectedValue = CheckNullStrip(@claim.Service)
          setServicesDropDownForClaimType(literal, selectedValue) 
          # set hidden field for submit
          @ClaimTypeLetter = lowerCase  
     
          # keep adjust claim id in session for stamping later after adjustment is added.
          render :claim
          return
       end 
    
  
  
     # initial screen logic. New Claims. 
      @claim = EmptyClaim()
      
    
       # --------------------- copy logic ------------------------------ 
       copyClaim = session[:copy] == "Copy" 
       session[:copyMessage] = nil
       doCopy = false
       if copyClaim then  
             doCopy = true
             claimNumber = session[:origionalClaimIdNUmber]
             newCopyClaimIdNumber = assignClaimId()
             session[:promisedIdForAdjorCopy] = newCopyClaimIdNumber 
             origionalClaimIdNumber = claimNumber.strip
             @message = "Enter claim #{newCopyClaimIdNumber} data for copy of claim #{origionalClaimIdNumber}."
             if ENV["A90UseApiCalls"] == "Yes" then 
                 o = GetClaimByNode(origionalClaimIdNumber)
             else 
                 o = Claim.find_by  ClaimIdNumber: origionalClaimIdNumber  
             end
             @ClaimStatus = o.ClaimStatus.strip
             @PatientFirst = o.PatientFirst.strip
             @PatientLast = o.PatientLast.strip
             @Procedure1 = o.Procedure1.strip
             @Procedure2 = CheckNullStrip(o.Procedure2)
             @Diagnosis1 = o.Diagnosis1.strip
             @Diagnosis2 = CheckNullStrip(o.Diagnosis2)
             @ClaimDescription = o.ClaimDescription.strip
             @Physician = o.Physician.strip
             @claim.CustomerId = o.CustomerId.strip
             @claim.PlanId = o.PlanId.strip.strip
             @Service = o.Service.strip
             @Clinic = CheckNullStrip(o.Clinic)
             @ClaimType = o.ClaimType.strip
             @DateService = FormatDateForScreen(o.DateService)
             @Referral = CheckNullStrip(o.Referral) 
             defaultDate = Time.new(1753,1,1)
             @claim.AdjustedDate = defaultDate
             # claim type regular variable non @.
             claimType = o.ClaimType.strip
 
             if claimType == "m" then 
                  
                   @DateConfine = FormatDateForScreen(o.DateConfine)
                   @DateRelease = FormatDateForScreen(o.DateRelease)
  
             elsif claimType == "d" then
                   @ToothNumber = CheckNullStrip(o.ToothNumber)
             elsif claimType == "v" then
                   @Eyeware = CheckNullStrip(o.Eyeware)
             elsif claimType == "x" then
                   @DrugName = CheckNullStrip(o.DrugName)
             else
                a = 1 
             end
             @ClaimType = claimType
              # initialize to medical - javascript must issue action to change 
             literal = getTypeLiteral(claimType)
             selectedValue = CheckNullStrip(o.Service)
             selectedValue = selectedValue.to_s 
             setServicesDropDownForClaimType(literal, selectedValue)
             session[:origionalClaimIdNUmber] = nil   
             session[:copyInEffect] = "Yes"  
             return
  
       end 
  
       @message = "Enter claim information." 
       
       initialClaimType = "m"
       @claim.ClaimType = initialClaimType  
       @ClaimType = initialClaimType
    
       # initialize to medical - javascript must issue action to change 
       literal = getTypeLiteral(initialClaimType)
       noSelectedValue = ""
       setServicesDropDownForClaimType(literal, noSelectedValue)
    
    end 

    def CheckNullStrip(value)
      if value == nil || value == "" then return "" end
      return value
    end

    def GetClaimByNode(claimIdNumber)
 
      urlPrefix = ENV['A90UrlPrefix']
      url = "/claim?id=" 
      actionString = urlPrefix + url + claimIdNumber 
      actionString = actionString.strip() 
      begin 
         connection = Excon.new(actionString, :connect_timeout => 15) 
         response = connection.get 
      rescue => e 
         log("excon claim read error... #{e.class} #{e.message}")
         return nil
      end 
     
      if response.status != 200  # not good read 
         return nil
      end   

      raw = response[:body]   
      claimdata = JSON.parse(raw)   
      index = 0
      claimFromList = claimdata[index]   
      oneClaim = claimHashToObjectNode(claimFromList)   
      return oneClaim

    end
     
    
    def claimadd
    
      # detect a type change  
      typeLiteral = params[:commit] 
      #puts "claim add 1 - parmams[:commit] is :  #{typeLiteral}."
      # claim types are 
      claimTypes = Array["Medical","Dental","Vision","Drug"]
      typeChangeRequetedByButton = claimTypes.include? typeLiteral
    
      if typeChangeRequetedByButton == true then 
        # Keep values entered so far when type changes
        @claim = ClaimFromScreen()
        # for the type change reset the Literal and Service Names !
        noSelectedValue = ""
        setServicesDropDownForClaimType(typeLiteral, noSelectedValue)
        # change claim type on the claim 
        @message = "Claim type changed to #{typeLiteral}."
        oneLetterType = getOneLetterType(typeLiteral)
        @claim.ClaimType = oneLetterType 
        # set hidden field for submit
        @ClaimTypeLetter = oneLetterType
        # screen type field display 
        @ClaimType = oneLetterType
        # now reshow the screen
        ReloadClaimScreen(@claim)
        render :claim
        return
      end
    
      # detect a menu button selection 
      menuButtonPressed = params[:commit]
      if menuButtonPressed == "Menu" then 
         redirect_to controller: :home, action: :menu 
         return
      end 
    
       # detect a history button selection 
       historyButtonPressed = params[:commit]
       if historyButtonPressed == "History" then 
          redirect_to controller: :claim, action: :history 
          return
       end 
  
       
       # detect a plan button selection 
       planButtonPressed = params[:commit]
       if planButtonPressed == "Plan" then 
          redirect_to controller: :customers, action: :plan 
          return
       end 
      
      # not a type change? That means a regular claim add submit. 
      @claim = ClaimFromScreen() 
     
    
      oneLetterType = params[:ClaimTypeLetter] 
      @claim.ClaimType = oneLetterType
      #puts "hidden posted claim type field is #{oneLetterType}."
       
      
      # pull in any meeded fields
      # add html validateion slots - will it be what we want ?? 
      # calc the covered amount via call back
    
      # use same claim number on copy operation  
      if session[:promisedIdForAdjorCopy] != "" 
         @claim.ClaimIdNumber = session[:promisedIdForAdjorCopy]
      else
         @claim.ClaimIdNumber = assignClaimId
      end
     
      custId = session[:custId]
      #puts "add claim cust id"
      #puts custId
      @claim.CustomerId = custId.strip

      @planButton = "no"
    
       # todo : add keep back with api call to customer for plan.
    
      #puts "add claim plan id"
      #puts planId
      #@claim.PlanId = planName

      
      @planButton = "no"

      # TO DO: api for this
      # TO DO: dup customer check on add.
 

      #planName = Customer.where(custId: custId).pluck(:custPlan)[0] 

      # claim add make sure customer has a plan  
      planName = getPlanId(custId)   
      planNotSetOnCustomer = ""
      if planName == nil || planName.strip == planNotSetOnCustomer then
        @planButton = "yes"
        @message = "1. Use plan screen to add a plan to customer." 
        literal = getTypeLiteral(oneLetterType)
        selectedValue = @claim.Service
        setServicesDropDownForClaimType(literal, selectedValue) 
        # set hidden field for submit 
        @ClaimTypeLetter = oneLetterType 
        @ClaimType = oneLetterType
        ReloadClaimScreen(@claim) 
        render :claim
        return
      end 

      @claim.PlanId = planName
     
      result = EditClaim(@claim) 
      if result != ""
         # type literal is 'create claim so pull from hidden field 
         #    
         ReloadClaimScreen(@claim) 
         literal = getTypeLiteral(oneLetterType)
         selectedValue = @claim.Service
         setServicesDropDownForClaimType(literal, selectedValue) 
         # set hidden field for submit 
         @ClaimTypeLetter = oneLetterType  
         @ClaimType = oneLetterType
         @message = result
         render :claim
         return
      end
     
    
        
      # service gives cost; plan gives percent paid ; result covered amount. 
      totalCostForService = getCost(@claim.ClaimType, @claim.Service) 
      coveredAmount = calculateCoveredAmountForPlan(totalCostForService, planName) 
      balanceOwed = totalCostForService - coveredAmount

      defaultDate = "1753-01-01" 
      if @claim.DateConfine == nil || @claim.DateConfine == "" then
         @claim.DateConfine = defaultDate
      end 
      if @claim.DateRelease == nil || @claim.DateRelease == "" then
         @claim.DateRelease = defaultDate
      end 
 
    
      @claim.TotalCharge = totalCostForService
      @claim.CoveredAmount = coveredAmount
      @claim.BalanceOwed = balanceOwed

      @claim.DateService = FormatForDB(@claim.DateService)
    
      # for medical claim supply date defaults for confined and released
      # if claim type medical
      @claim.DateConfine = FormatForDB(@claim.DateConfine)
      @claim.DateRelease = FormatForDB(@claim.DateRelease)
    
      # init general fiedls  
      @claim.ClaimStatus = "Entered"
      @claim.PaymentAction = ""
      @claim.AppAdjusting = ""
      @claim.PaymentAmount = 0
    
      # init dates  f
      useDefault = ""
      useCurrent = "useCurrent"
      @claim.AdjustedDate = FormatDateForDB(useDefault)
      @claim.PaymentDate = FormatDateForDB(useDefault) 
      # fix this TODO: for now use default date.  
      @claim.DateAdded = FormatDateForDB(useCurrent)
      @claim.AppAdjusting = "" 
  
       # clear fields not on this claim type. 
       claimType = @claim.ClaimType
       #puts "claim type clear is so field are cleared: #{claimType}."

       defaultDate = FormatDateForDB(useDefault)

       #log("fill in fill in fields claim type is #{claimType}")
       
        if claimType == "m" then
    
           @claim.Eyeware = ""
           @claim.DrugName = ""
           @claim.ToothNumber = 0
    
       elsif claimType == "d" then
    
           @claim.Eyeware = ""
           @claim.DrugName = ""
           @claim.DateConfine = defaultDate
           @claim.DateRelease = defaultDate
    
       elsif claimType == "v" then
    
           @claim.DrugName = ""
           @claim.ToothNumber = 0
           @claim.DateConfine = defaultDate
           @claim.DateRelease = defaultDate
    
       elsif claimType == "x" then
    
          @claim.Eyeware = ""
          @claim.ToothNumber = 0
          @claim.DateConfine = defaultDate
          @claim.DateRelease = defaultDate
    
       else 
          a = 1 
       end 
     
       claimIdToAdjust = session[:adjustClaimId]
       if claimIdToAdjust != nil then
          @claim.AdjustedClaimId = claimIdToAdjust
          @claim.ClaimStatus = "Adjustment"
       end
    
       if ENV["A90UseApiCalls"] == "Yes" then 

          result = ClaimAddByNode(@claim)  
          if result == false then
             flash[:message] = "Claim add failed"
             redirect_to controller: :home, action: :menu 
             return 
          end

       else
    
            if @claim.save  
               a = 1
            else  
               flash[:message] = "Claim add failed"
               redirect_to controller: :home, action: :menu 
               return 
            end 

        end
 

      # if this claim is an adjustement - stamp the adjusted claim with this claim number
      # in the adjusting claim id field

      # new or copy operations
      newClaimId = @claim.ClaimIdNumber

      isCopy = false
      checkCopy = session[:copyInEffect]
      if checkCopy == "Yes" then
         isCopy = true
      end

      turnOff = ""
      session[:promisedIdForAdjorCopy] = turnOff
      
      claimIdToAdjust = session[:adjustClaimId]
      if claimIdToAdjust != nil then 
         StampAdjustedClaim(claimIdToAdjust,@claim.ClaimIdNumber)  
         addRecord("Adj", newClaimId)
         flash[:message] = "Claim #{claimIdToAdjust} adjusted successfully with #{@claim.ClaimIdNumber}."  
      elsif 
         if isCopy == true then  
            addRecord("Cpy", newClaimId)
            session[:copy] = nil
         elsif 
            addRecord("New", newClaimId)
         end 
         flash[:message] = "Claim #{@claim.ClaimIdNumber} added successfully."  
      end
      session[:adjustClaimId] = nil 
      session[:copyInEffect] = ""
      redirect_to controller: :home, action: :menu 
      return
    
    
    end

    def ReloadClaimScreen(claim)
 
      @PatientFirst = claim.PatientFirst.strip
      @PatientLast = claim.PatientLast.strip
      @Procedure1 = claim.Procedure1.strip
      @Procedure2 = CheckNullStrip(claim.Procedure2)
      @Diagnosis1 = claim.Diagnosis1.strip
      @Diagnosis2 = CheckNullStrip(claim.Diagnosis2)
      @ClaimDescription = claim.ClaimDescription.strip
      @Physician = claim.Physician.strip  
      @Service = claim.Service.strip
      @Clinic =CheckNullStrip(claim.Clinic)
      claimType = claim.ClaimType.strip
      @DateService = formatDateForScreen(claim.DateService)
      @Referral = CheckNullStrip(claim.Referral)
      @AdjustingClaimId = ""
      @AdjustedClaimId = "" 
      defaultDate = Time.new(1753,1,1)
      @AdjustedDate = defaultDate
      claimType = claim.ClaimType.strip
      @DateService = claim.DateService

      if claimType == "m" then 
              
        @DateConfine = formatDateForScreen(claim.DateConfine)
        @DateRelease = formatDateForScreen(claim.DateRelease)

     elsif claimType == "d" then
           @ToothNumber = CheckNullStrip(claim.ToothNumber)
     elsif claimType == "v" then
           @Eyeware = CheckNullStrip(claim.Eyeware)
     elsif claimType == "x" then
           @DrugName = CheckNullStrip(claim.DrugName)
     else
        a = 1 
     end

    end

    def ClaimAddByNode(claim)

      urlPrefix = ENV['A90UrlPrefix']
      apiClaimAdd = "/addClaim"   
      sendString = urlPrefix + apiClaimAdd

      token = session[:A65Token] 
        

      # convert claim data to hash
      claimHash = claimToHash(claim, token) # create hash 

      # convert hash to json 
      claimJson = claimHash.to_json
 

      # make the call 
      begin
         response = Excon.post(sendString, 
           :body => claimJson, 
           :headers => {  "Content-Type" =>  "application/json",
                          "Charset" => "UTF-8" }) 
       rescue => e
          log("claim add send error : #{e.class} #{e.message}.")
          return false
       end

       # check the status 
       status = response.status
       if status == 200 then
          return true
       else
          return false
       end  

    end

    def claimToHash(claim, token)

       claimHash = Hash[ 'ClaimIdNumber' =>  claim.ClaimIdNumber,
                     'ClaimDescription' =>  claim.ClaimDescription,
                     'CustomerId' =>  claim.CustomerId,
                     'PlanId' =>  claim.PlanId,
                     'PatientFirst' =>  claim.PatientFirst,
                     'PatientLast' =>  claim.PatientLast,
                     'Diagnosis1' =>  claim.Diagnosis1,
                     'Diagnosis2' =>  claim.Diagnosis2,
                     'Procedure1' =>  claim.Procedure1,
                     'Procedure2' =>  claim.Procedure2,
                     'Procedure3' =>  claim.Procedure3,
                     'Physician' =>  claim.Physician,
                     'Clinic' =>  claim.Clinic,
                     'DateService' =>  claim.DateService,
                     'Service' =>  claim.Service,
                     'Location' =>  claim.Location,
                     'TotalCharge' =>  claim.TotalCharge,
                     'CoveredAmount' =>  claim.CoveredAmount,
                     'BalanceOwed' =>  claim.BalanceOwed,
                     'PaymentAmount' =>  claim.PaymentAmount,
                     'PaymentDate' =>  claim.PaymentDate,
                     'PaymentAction' =>  claim.PaymentAction,
                     'DateAdded' =>  claim.DateAdded,
                     'AdjustedClaimId' =>  claim.AdjustedClaimId,
                     'AdjustingClaimId' =>  claim.AdjustingClaimId,
                     'AdjustedDate' =>  claim.AdjustedDate,
                     'AppAdjusting' =>  claim.AppAdjusting,
                     'ClaimStatus' =>  claim.ClaimStatus,
                     'Referral' =>  claim.Referral, 
                     'ClaimType' =>  claim.ClaimType,
                     'DateConfine' =>  claim.DateConfine,
                     'DateRelease' =>  claim.DateRelease,
                     'ToothNumber' =>  claim.ToothNumber,
                     'DrugName' =>  claim.DrugName,
                     'Eyeware' =>  claim.Eyeware, 
                     '_csrf' => token
                 ]


       return claimHash

    end
 
    
    def StampByNode(adjustedClaimIdNumber, adjustingIdNumber)
 

      currentDate = Time.current 
      date = currentDate.strftime("%Y-%m-%d")

      token = session["A65Token"]
      
      adjustingHash = Hash[     'ClaimIdNumber' => adjustedClaimIdNumber,
                                'AdjustmentIdNumber' => adjustingIdNumber,
                                'AdjustedDate' => date,
                                'AppAdjusting' => 'A90',
                                '_csrf' => token ] 
     
      # 
      #log("adjusting hash is : ${adjustingHash}.")
      urlPrefix = ENV['A90UrlPrefix']
      adjustApi = '/stampAdjustedClaim'

      sendString = urlPrefix + adjustApi
      #   
      #   'Content-Type': 'application/json', 'charset': 'utf-8' 
      json = adjustingHash.to_json
      #  
      # 
      # add mew claim: REST 'post'.
      begin
        response = Excon.put(sendString, 
          :body => json, 
          :headers => {  
                         "Content-Type" =>  "application/json",
                         "Charset" => "UTF-8" }) 
      rescue => e
         log("adj stamp error : #{e.class} #{e.message}.")
         return false
      end
      #
      # 

      resp = response[:body] 
      
      
      if resp == "OK"
         return true
      else 
         return false
      end  


    end

    def StampAdjustedClaim(adjustedClaimIdNumber , adjustingIdNumber)
        
       if ENV["A90UseApiCalls"] == "Yes" then  
          result = StampByNode(adjustedClaimIdNumber, adjustingIdNumber) 
          if result == true 
            return  
          else 
            @message = "Adjustement Stamp Error"
            redirect_to controller: :home, action: :menu 
            return
          end
       end
          
       #puts 'stamping claim'
       @adjustedClaim = Claim.find_by ClaimIdNumber: adjustedClaimIdNumber
       id = @adjustedClaim.AdjustedClaimId
       #puts "adj claim adjust(ed) claim id is #{id}"
       @adjustedClaim.AdjustingClaimId = adjustingIdNumber
       @adjustedClaim.AppAdjusting = "A90" 
       currentDate = Time.current
       @adjustedClaim.AdjustedDate = currentDate
       @adjustedClaim.ClaimStatus = "Adjusted"
       #puts @adjustedClaim
       if @adjustedClaim.save then
          #puts 'good stamp'
          return
       else
          #puts 'bad stamp'
          message = "Adjustment: Error Stampping claim #{adjustedClaimIdNumber}." 
          redirect_to controller: :home, action: :menu 
          return
       end
    
    end
 
    
    
    def getOneLetterType(longType)
    
       type = "z"
       #puts "get one letter type - longType #{longType}."
       if longType == "Medical"
          type = "m"
       elsif longType == "Dental"
          type = "d"
       elsif longType == "Vision"
          type = "v"
       elsif longType == "Drug"
          type = "x"
       else
          type = "u"
       end
       #puts "get one letter type #{type}."
       return type
    end
    
    def getTypeLiteral(one)
       lit = "Unknown"
       #puts "get type literal for letter:  #{one}."
       if one == "m"
          lit = "Medical"
       elsif one == "d"
          lit = "Dental"
       elsif one == "v"
          lit = "Vision"
       elsif one == "x"
          lit = "Drug"
       else
          lit = "Unknown"
       end
       #puts "get literal #{lit}."
       return lit
    end
    
    def setServicesDropDownForClaimType(literal , selectedValue)
 
      _selectedValue = selectedValue.strip
      # pass selected "" not to select anything.
  
       @selectedService = ""
       # puts "setServicesDropDownForClaimType: typeLiteral is :#{literal}."
       @ClaimTypeLiteral = literal 
       lookup = getOneLetterType(literal)  
      # puts "setServicesDropDownForClaimType: lit is #{literal}, lookup is :#{lookup}." 
       @ClaimTypeLetter = lookup
       #@Service = Service.where(ClaimType: lookup).pluck(:ServiceName) 

       urlPrefix = ENV['A90UrlPrefix']
       apiServices = "/readServices"  
       actionString = urlPrefix + apiServices
    
   
       begin 
         connection = Excon.new(actionString, :connect_timeout => 15) 
         response = connection.get 
       rescue => e 
           log("excon serv read error...")
           return nil
       end
       if response.status != 200  # not good read 
          return nil
       end
       services = response.body  
       servicesHash = JSON.parse(services) # create hash 
       @serviceList = ServicesToServiceHash(servicesHash, lookup) 
       @serviceList.each do | s |  
          if lookup == s['ClaimType'].strip && _selectedValue == s['ServiceName'].strip 
             s['Selected'] = "Yes"
          end
       end  
    end

    def ServicesToServiceHash(h, inputClaimType)

      serviceNames = Array.new
      h.each do | h |
         serviceName = h['ServiceName'].strip
         claimType = h['ClaimType']
         if inputClaimType == claimType then
            entry = Hash['ServiceName' => serviceName, 'ClaimType' => claimType,
                    'Selected' => "No" ]
            serviceNames.push(entry)
         end
      end
      return serviceNames

    end

    def ServiceToServiceObjects(h)
      
      serviceObjects = Array.new
      h.each do | h |
         s = Service.new
         s.ServiceName = h['ServiceName'] 
         s.ClaimTypeLiteral = h['ClaimTypeLiteral']
         s.Cost = h['Cost'] 
         serviceObjects.push(s)
      end
      return serviceObjects 

    end 

    def FindServiceCost(claimType, service)

      urlPrefix = ENV['A90UrlPrefix']
      apiServices = "/readServices"  
      actionString = urlPrefix + apiServices
   
  
      begin 
        connection = Excon.new(actionString, :connect_timeout => 15 ) 
        response = connection.get 
      rescue => e 
          log("excon serv2 read error...")
          return 0.0
      end
      #log "s2 #{response.status}"
      if response.status != 200  # not good read 
         return 0.0
      end
      services = response.body  
      servicesHash = JSON.parse(services) # create hash 
      serviceCost = 0.0
      @serviceCostList = ServiceToServiceObjects(servicesHash) 
      claimTypeLiteral = getTypeLiteral(claimType)
      @serviceCostList.each do | s | 
          sClaimTypeLiteral = s.ClaimTypeLiteral.strip
          sServiceName = s.ServiceName.strip 
         if claimTypeLiteral == sClaimTypeLiteral && service == sServiceName 
            serviceCost = s.Cost.to_f 
         end
      end 
      return serviceCost
    end

    def getPlans

      urlPrefix = ENV['A90UrlPrefix']
      apiPlans = "/readPlans"  
      actionString = urlPrefix + apiPlans
   
  
      begin 
        connection = Excon.new(actionString, :connect_timeout => 15) 
        response = connection.get 
      rescue => e 
          log("excon plan read error...")
          return nil
      end 
      log "plans read response status is #{response.status}"
      if response.status != 200  # not good read 
         return nil
      end
      plans = response.body  
      planHash = JSON.parse(plans) # create hash 
      @planList = PlanToPlanObjects(planHash)  
      return @planList
    end

    def PlanToPlanObjects(h)
      
      planObjects = Array.new
      h.each do | h |
         p = Plan.new
         p.PlanName = h['PlanName']
         p.PlanLiteral = h['PlanLiteral']
         p.Percent = h['Percent'] 
         planObjects.push(p)
      end
      return planObjects  
    end 
    
    def getCost(claimType, service) 
        lookup = service.strip 
        totalCost = FindServiceCost(claimType, service) 
        return totalCost
    end
    
    def calculateCoveredAmountForPlan(totalCost, planName)  
        # get percentage covered for assigned plan
        percent = GetPlanRecordPercent(planName)  
        intPercent = percent.round()
        coveredCost = (totalCost * intPercent) / 100 
        #log "covered cost #{coveredCost}"
        return coveredCost
    end

    def GetPlanRecordPercent(planName)
        input_plan_name = planName.strip 
        percent = 0.0
        @planList = getPlans() 
        @planList.each do | p | 
            name = p.PlanName.strip  
            if name == input_plan_name  
               percent = p.Percent.to_f 
            end
        end 
        return percent
    end
    
    def getCustId
        # get cust id from session if not throw exception
       custId = session[:custid] 
    end
    
    def getPlanId(custId)
        # get plan Id from customer record 
       #customer = Customer.find_by! custId: 1  
       customer = CustomerNodeRead(custId) 
       custId = customer['custId']
       #log "cust id from plan read is: #{custId}"
       plan = customer['custPlan']
       #debug
      # log "customer plan read is: #{plan}" 
       #if plan == nil || plan == "" then
       #   log 'plan default temporary.'
       #  plan = "none"
       #end
       return plan
    end
    
    def formatToDefaultIfNotEntered(input)
        # format to preferred default if not entered 1.1.1753 
        supplyDefaultValue = "1753-01-01T00:00:00"
        screenDate = input.to_s 
        needDefault = screenDate == nil || screenDate == ""
        if needDefault
           use = supplyDefaultValue
        else
            m = screenDate[0..1] 
            d = screenDate[2..3]
            length = screenDate.length()
            if length == 6 
               y = screenDate[4..5] 
               check = y.to_i
               nextYear = 21
               if y > check then
                  y = "19" + y
               else
                  y = "20" + Y
               end
            else
               y = screenDate[4..7]
            end
        end 
        suffix = "T00:00:00"
        output = y + dash + m + dash + d + suffix 
        return output
    end
    
    def assignClaimId
    
        # var id= 'CL-' + this.today + '-' + this.time; 
        # CL-8-8-2022-16:29:30          
        t = Time.current
        assignedId = t.strftime("CL-%M-%d-%Y-%I:%M:%S")   
    end

    def formatDateForScreen(dbDate)
      # api needs yyyy-mm-dd to mm/dd/yy
      work = dbDate.to_s 
      #log("formatDateForScreen #{work}")
      if dbDate == nil || work == "" 
         output = "09/09/2022"
         #log("formatDateForScreen default output...")
         return output
      end

      y = work[0..3]
      m = work[5..6]
      d = work[8..9]
      y2 = work[2..3]
      slash = "/"

      output = m + slash +  d + slash + y2

      if y == "1753" then
         output = ""
      end
      
      #log("formatDateForScreen output  #{output}")
      return output 
    end
    
    
    def history 
 
     session[:adjustClaimId] = nil
  
     # Since Procedure3 is unused store count there!
     
     entry = getRecord(0)
     none = "none"
     comma = ","
     claim1 = ""
     claim2 = ""
     @showButton1 = "No"
     @showButton2 = "No" 
     if entry != none then 
        arr = entry.split(/,/)
        @act1 = arr[0] # literal shown on screen
        @clm1 = arr[0] + comma + arr[1] # claim id on button for action processed by submit 
        claim1 = arr[1].strip 
        @showButton1 = "Yes"
     end
     entry = getRecord(1)
     if entry != none then
       arr = entry.split(/,/)
       @act2 = arr[0] # literal shown on screen
       @clm2 = arr[0] + comma + arr[1] # claim id on button for action processed by submit 
       claim2 = arr[1].strip()
       @showButton2 = "Yes"
     end
    
      custId = session[:custId]   
      act1count = -1
      act2count = -1 
  
     

      # /History/{id}
      customerId = session[:custId]
      urlPrefix = ENV['A90UrlPrefix']
      url = "/history?id="  # a45 uri query string/
      actionString = urlPrefix + url + customerId.to_s.strip
      #log("history #{actionString}")
      connection = Excon.new(actionString, :connect_timeout => 15) 
      response = connection.get  

      if response.status == 404
         flash[:message] = "No claims found."
         redirect_to controller: :home, action:  :menu 
         return
      end

      if response.status != 200
         flash[:message] = "No claims found. status is : #{response.status}."
         redirect_to controller: :home, action:  :menu 
         return
      end 
 
      claimList = response.body   

      raw = response[:body]   
      claimList = JSON.parse(raw) 
      total = claimList.length
      
      first = 0 
      half =  (total - (total % 2))/2  
      last = total - 1
      count = 0 

      @claims = Array.new
      index = 0
      while index < total
         # 
         claimFromList = claimList[index]   
         oneClaim = claimHashToObjectNode(claimFromList)  
         #
         oneClaim.ClaimStatus = oneClaim.ClaimStatus.strip 
         work = oneClaim.ClaimIdNumber.to_s
         work2 = work.strip()
         oneClaim.ClaimIdNumber = work2
         oneClaim.PaymentAction = "" 
         #
         if count == first 
            oneClaim.PaymentAction = "top"
         end
         if count == half
            oneClaim.PaymentAction = "mid"
         end
         if count == last
            oneClaim.PaymentAction = "bot"
         end
         #
         if work2 == claim1 then
            oneClaim.PaymentAction += "act1"
         end
         if work2 == claim2 then
            oneClaim.PaymentAction += "act2"
         end 
         count = count + 1
         oneClaim.AppAdjusting = count.to_s
         # store seq display in unused field.
         oneClaim.Procedure3 = count.to_s
         oneClaim.DateService = formatDateForScreen(oneClaim.DateService) 
         oneClaim.PaymentDate = formatDateForScreen(oneClaim.PaymentDate) 
         oneClaim.DateAdded = formatDateForScreen(oneClaim.DateAdded) 
         oneClaim.AdjustedDate = formatDateForScreen(oneClaim.AdjustedDate) 
         oneClaim.DateConfine = formatDateForScreen(oneClaim.DateConfine) 
         oneClaim.DateRelease = formatDateForScreen(oneClaim.DateRelease)
         # format dates for screen 
         @claims.push(oneClaim) 
         index = index + 1

      end
      #  
      if @claims == nil then 
         flash[:message] = "1. No Claims found."
         redirect_to controller: :home, action:  :menu 
      end
       
  
    end

    def FindHistory(customerId) 

            @claims = Array.new
            Claim.where(CustomerId: custId).find_each do | oneClaim | 
                  # add to array of historical @claims
                  oneClaim.ClaimStatus = oneClaim.ClaimStatus.strip
                  work = oneClaim.ClaimIdNumber.to_s
                  work2 = work.strip()
                  oneClaim.ClaimIdNumber = work2
                  oneClaim.PaymentAction = "" 
                  # use Encrypted to set markers top,bot and middle.  
                  if work2 == claim1 then
                  act1count = count 
                  end
                  if work2 == claim2 then
                  act2count = count
                  end 
                  count = count + 1
                  # store seq display in unused field.
                  oneClaim.Procedure3 = count.to_s
                  @claims.push(oneClaim)
            end 
            return @claims
      end

    def FindHistoryByApi(customerId)
 

         # api/Claim/History/{id} 

         urlPrefix = ENV['A90UrlPrefix']
         url = "api/Claim/History/" 
         actionString = urlPrefix + url + customerId
 

         begin 
            connection = Excon.new(actionString, :connect_timeout => 15) 
            response = connection.get 
         rescue => e 
            log("excon hist  read error...")
            return nil
         end
         #log(response.status)
         if response.status != 200  # not good read 
            return nil
         end
         claimList = response.body  
         claimListHash = JSON.parse(claimList) # create hash   
         # might have to write claimHashToObject to build object array
         #return claimListHash 

         claimObjectList = Array.new
         claimListHash.each do | hi | # hash item is 'hi'.
            aClaim = claimHashToObject(hi)
            claimObjectList.push(aClaim)
         end
         #
         if claimObjectList == nil 
            claimObjectList.push("")
         end
         return claimObjectList
         #
    end 

    
    def claimHashToObjectNode(h) 
      c = EmptyClaim()
       
      c.ClaimIdNumber = h['ClaimIdNumber']
      c.ClaimDescription = h['ClaimDescription']
      c.CustomerId = h['CustomerId']
      c.PlanId =  h['PlanId']
      c.PatientFirst = h['PatientFirst']
      c.PatientLast = h['PatientLast']
      c.Diagnosis1 = h['Diagnosis1'] 
      c.Diagnosis2 = h['Diagnosis2']
      c.Procedure1 = h['Procedure1'] 
      c.Procedure2 = h['Procedure2']    
      c.Procedure3 = ""
      c.Physician= h['Physician']
      c.Clinic = h['Clinic']
      c.DateService = h['DateService']
      c.Service = h['Service']
      c.Location = h['Location']
      c.TotalCharge = h['TotalCharge']
      c.CoveredAmount = h['CoveredAmount']
      c.BalanceOwed = h['BalanceOwed']
      c.PaymentAmount = h['PaymentAmount']
      c.PaymentDate = h['PaymentDate']
      c.DateAdded = h['DateAdded']
      c.AdjustedClaimId = h['AdjustedClaimId']
      c.AdjustingClaimId = h['AdjustingClaimId']
      c.AdjustedDate = h['AdjustedDate']
      c.AppAdjusting = h['AppAdjusting']
      c.ClaimStatus = h['ClaimStatus']
      c.Referral = h['Referral']
      c.PaymentAction = h['PaymentAction']
      c.ClaimType = h['ClaimType']
      c.DateConfine = h['DateConfine']
      c.DateRelease = h['DateRelease']
      c.ToothNumber = h['ToothNumber']
      c.DrugName = h['DrugName']
      c.Eyeware = h['Eyeware'] 
      c.PaymentAction = ""
      #  
      return c
  end

    def claimHashToObject(h) 
        c = EmptyClaim()
        
        c.id = h['id']
        c.ClaimIdNumber = h['claimIdNumber']
        c.ClaimDescription = h['claimDescription']
        c.CustomerId = h['customerId']
        c.PlanId =  h['planId']
        c.PatientFirst = h['patientFirst']
        c.PatientLast = h['patientLast']
        c.Diagnosis1 = h['diagnosis1'] 
        c.Diagnosis2 = h['diagnosis2']
        c.Procedure1 = h['procedure1'] 
        c.Procedure2 = h['procedure2']    
        c.Procedure3 = ""
        c.Physician= h['physician']
        c.Clinic = h['plinic']
        c.DateService = h['dateService']
        c.Service = h['service']
        c.Location = h['location']
        c.TotalCharge = h['totalCharge']
        c.CoveredAmount = h['coveredAmount']
        c.BalanceOwed = h['balanceOwed']
        c.PaymentAmount = h['paymentAmount']
        c.PaymentDate = h['paymentDate']
        c.DateAdded = h['dateAdded']
        c.AdjustedClaimId = h['adjustedClaimId']
        c.AdjustingClaimId = h['adjustingClaimId']
        c.AdjustedDate = h['adjustedDate']
        c.AppAdjusting = h['appAdjusting']
        c.ClaimStatus = h['claimStatus']
        c.Referral = h['referral']
        c.PaymentAction = h['paymentAction']
        c.ClaimType = h['claimType']
        c.DateConfine = h['dateConfine']
        c.DateRelease = h['dateRelease']
        c.ToothNumber = h['toothNumber']
        c.DrugName = h['drugName']
        c.Eyeware = h['eyeware'] 
        c.PaymentAction = ""
        #  
        return c
    end

    def historynext
    
       submitValue = params[:commit] 
   
     #  puts "history next: submit value #{submitValue}."
       if submitValue == "Menu" then 
          redirect_to controller: :home, action:  :menu 
          return
       end
       if submitValue == "Claim"
          redirect_to controller: :claim, action: :claim
          return
       end
       if submitValue[0..3] == "Copy"
        #  puts "submit value history for copy action #{submitValue}"
          session[:copy] = "Copy"
          value = submitValue[4..-1]
        #  puts "value is #{value}."
          session[:origionalClaimIdNUmber] = value.strip # pos 4 to end.
          a = session[:origionalClaimIdNUmber]
      #    puts "verify a /#{a}/"
          redirect_to controller: :claim, action: :claim
          return
       end
       if submitValue[0..2] == "Pay"
          session[:payClaimId] = submitValue[3..-1]
          redirect_to controller: :claim, action: :payment
          return
       end
       submitvalue = params[:commit] 
       adjustmentClaimNumber = submitvalue.strip
       validPrefix = "CL-"
       if adjustmentClaimNumber[0..2] != validPrefix
          message = "Error: invalid claim adjust number #{adjustmentClaimNumber}."
          flash[:message] = message 
          redirect_to controller: :home, action:  :menu 
          return
       end
       # have a good claim id proceed to load claim screen with it.
       session[:adjustClaimId] = adjustmentClaimNumber
      # puts "hist next adj claim id number is: #{adjustmentClaimNumber}."
       redirect_to controller: :claim, action: :claim
       return 
    end
    
    def EditClaim(claim)
    
        message = ""
    
        if claim.DateService == nil
           message = "Please enter valid date of service."
           return message
        end 
    
        standard = Regexp.new("^[\s.a-zA-Z0-9]+$") 
        standard_or_space= Regexp.new("^[\s.a-zA-Z0-9]*$")   
        
        standard_tooth = Regexp.new("^[1-9]+$") 
  
        if claim.PatientFirst.strip == ""
           message = "Patient first name is required."
           return message
        end
        
        if  claim.PatientLast.strip  == ""
           message = "Patient last name is required."
           return message
        end
    
        if standard !~ claim.PatientFirst   
          message = "Please enter a valid Patient first name  with letters or numbers." 
          return message
        end
    
        if standard !~ claim.PatientLast   
          message = "Please enter a valid Patient last name  with letters or numbers." 
          return message
        end
    
        if standard_or_space !~ claim.ClaimDescription  
          message = "Please enter a valid Claim Description  with letters or numbers." 
          return message
        end
    
        if standard !~ claim.Diagnosis1  || claim.Diagnosis1.strip == "" then
          message = "Please enter a valid diagnosis code 1  with letters or numbers." 
          return message
        end
    
        if standard_or_space !~ claim.Diagnosis2  
          message = "Please enter a valid diagnosis code 2  with letters or numbers or leave blank." 
          return message
        end
    
        if standard !~ claim.Procedure1  || claim.Procedure1.strip == "" then
          message = "Please enter a valid procedure code 1  with letters or numbers." 
          return message
        end
    
        if standard_or_space !~ claim.Procedure2  
          message = "Please enter a valid procedure code 2  with letters or numbers or leave blank." 
          return message
        end
    
        if standard !~ claim.Physician  || claim.Physician.strip == "" then
          message = "Please enter a valid physican name  with letters or numbers." 
          return message
        end
    
        if standard_or_space !~ claim.Clinic  
          message = "Please enter a valid clinic name  with letters or numbers or leave blank." 
          return message
        end
    
        if standard_or_space !~ claim.Referral  
          message = "Please enter a valid referral  with letters or numbers or leave blank." 
          return message
        end
    
        claimType = claim.ClaimType
    
        #puts "edit: claim eyeware value #{claim.Eyeware}."
        #puts "edit: drug name #{claim.DrugName}."
    
        # edit by claim type
        if claimType == "m" then
    
             # confine and release dates have defalt values supplied if not
             # entered.
    
        elsif claimType == "d" then 
          #puts "tn #{claim.ToothNumber}"
          toothNumber = claim.ToothNumber.to_s 
          #puts "tn2 #{toothNumber}"
          #puts "tooth no /#{toothNumber}/"
          if standard_tooth !~ toothNumber  || toothNumber == nil then
             message = "Tooth number must be greater than zero and numeric." 
             return message
           end
    
        elsif claimType == "v" then
    
          eyeware = claim.Eyeware.strip
          if standard !~ eyeware  || eyeware == nil then
             message = "Please enter a valid Eyeware name with letters or numbers." 
             return message
           end
    
        elsif claimType == "x" then
    
          drugName = claim.DrugName.strip
          if standard !~ drugName  || drugName == nil then
             message = "Please enter a valid Drug name with letters or numbers." 
             return message
           end
    
        else 
           e = 1
        end
         
        empty_message_means_no_errors = ""
        return empty_message_means_no_errors
    
    end
  
    
  
    def payment 
      
     if notSignedIn() then
        redirect_to controller: :customers, action:  :notauthorized 
        return
     end
  

     #@message = "Payment opton unavailable at this time."
     #flash[:message] = @message
     #redirect_to controller: :home, action:  :menu


      # fill in claim id and message.
      @claimIdNumber = session[:payClaimId]  
      @message = "Enter Payment Amount" 
  
      
    end
  
    def payclaim
  
           message = ""  
           work = params['payamount'] 
           claimId = session[:payClaimId] # render payment goes to payclaim so pull from session.
           claimIdNumber = claimId.strip() 
           #log("payment claim id number is #{claimIdNumber}")
  
           # update claim with payment amount and payment date.   
           #puts "input payment amount .#{work}."
           
        
           if work == nil
              @message = "Please enter payment amount for claim #{claimIdNumber}"
              render :payment
              return
           end 
  
           paymentPattern = Regexp.new("^[0-9].[0-9]+$")   
           
           paymentPattern2 = Regexp.new("^[0-9]+$")   
  
           if paymentPattern !~ work && paymentPattern2 !~ work
              @message = "Invalid Amount." 
              render :payment
              return
           end
  
           begin
              floatAmount = work.to_f 
           rescue
              @message = "Invalid float amount" 
              render :payment
              return
           end 
           
           currentDate = Time.current  
           if ENV["A90UseApiCalls"] == "Yes" then  
               resp = PayClaimByNode(claimIdNumber,  floatAmount)
               if resp == false then
                  @message = "Claim Payment Update error...." 
                  render :payment
                  return
               end
           else
               @claim = Claim.find_by(ClaimIdNumber: claimIdNumber)
               @claim.update(PaymentDate: currentDate, PaymentAmount: floatAmount, ClaimStatus: "Paid")
           end 
           
           addRecord("Pay", claimIdNumber)
            
           redirect_to controller: :home, action: :menu 
           return
  
    end

   def PayClaimByNode(claimIdNumber, floatAmount)

   
   currentDate = Time.current 
   date = currentDate.strftime("%Y-%m-%d") 
   token = session["A65Token"]

   payHash = Hash[ "action" => "pay",
                   "claimIdNumber" => claimIdNumber.strip,
                   "amount" => floatAmount,
                   "date" => date,
                   "_csrf" => token]
   #
   urlPrefix = ENV['A90UrlPrefix']
   apiPayAction = "/setClaimStatus"  
   # 
   json = payHash.to_json
   #
   # may need a token ...
   # one last thing.... add the token to the header!
   # 
   sendString = urlPrefix + apiPayAction
   #   'Content-Type': 'application/json', 'charset': 'utf-8' 
 
   # 
   begin
     response = Excon.put(sendString,   
       :body => json,   
       :headers => {  
                      "Content-Type" =>  "application/json",
                      "Charset" => "UTF-8" }) 
   rescue => e
      log("claim payment send error : #{e.class} #{e.message}.") 
      return false
   end
   #
   
  
   if response.status = 200 then
      return true
   else 
      return false
   end 

  end
 
 
  
    
  def notSignedIn
  
     # prevent unauthorized access
     checkForYes = session[:signin]
     if checkForYes == "yes" then
        return false 
     end  
     return true
    end
  
     # Release Two Methods - maintain history positioning buttons.
  
     def addRecord(action,claimIdNumber)
  
        # add an entry for action session :entry1 :entry2
        # act should be Adj, Cpy, New, etc.
        #  
  
        entry1 = session[:entry1]
        entry2 = session[:entry2]
   
  
        # take last digit(s) of claim id after colon.
        # so if claim id is xxxx:1 we get  -1 and create Adj-1 for example.
        colon = ":"
        dash = "-"
        colonPosition = claimIdNumber.index(colon)
        pullPosition = colonPosition + 1
        secondColonPosition = claimIdNumber.index(colon,pullPosition)
        finalPullPosition = secondColonPosition + 1
        endofstring = -1
        lastDigits = claimIdNumber[finalPullPosition..endofstring]
        lastValue = dash + lastDigits
        act = action + lastValue
        stringClaimIdNumber = claimIdNumber.to_s  
   
        if entry1 == nil then
           data = act + ',' + stringClaimIdNumber
           session[:entry1] = data 
           return
        end
  
        if entry2 == nil then 
           data = act + ',' + stringClaimIdNumber   
           session[:entry2] = data 
           return
        end
  
        # both used entry 1 most recent - drop entry 2
        # if claim matches existing entry then replace THAT entry else
        # do the first in first out roll out. 
   
        work = session[:entry1]
        session[:entry2] = work 
        data = act + ',' + stringClaimIdNumber
        session[:entry1] = data 
   
        return 
     end
  
     def show()
        
        e1 = session[:entry1]
        e2 = session[:entry2]
        log "addRecord"
        log "========="
        log "session entry 1 #{e1}" 
        log "session entry 2 #{e2}"
        log "========="
        log " "
     end
  
     def getRecord(indicator)
   
   
        if indicator != 0 && indicator != 1 then 
           return "none"
        end
   
  
        # assemble string   action,claim;action,claim
        output = nil
        if indicator == 0 then
           output = session[:entry1] 
        end
        if indicator == 1 then
           output = session[:entry2] 
        end
        if output == nil then 
           return "none"
        end 
        return output 
  
     end
  
     def log(value)
         Rails.logger.info(" log: " + value)
     end

  def CustomerNodeRead(custId) 
 
   
   urlPrefix = ENV['A90UrlPrefix']
   apiSigninReadUrl = "/cust?id=" + custId.strip
   actionString = urlPrefix + apiSigninReadUrl
 
   log 'claim cust node read routine....'
   begin 
     connection = Excon.new(actionString, :connect_timeout => 15) 
     response = connection.get 
   rescue => e 
       log("excon cust read error...")
       return nil
   end 
     # a45 returns null for 500 .
     if response == nil then
        return nil
    end 
  
    raw = response[:body]
    resp = JSON.parse(raw)
    customer = resp['Customer'] 
    status = resp['Status']

    #log 'customer'
    #log customer.to_s
    #log 'status'
   # log status

    if status != "Successful" then
       return nil
    end  
    
    return customer

  end
 
 

 def customerHashToObject(h)

   c = Customer.new

   # do not use openstruct
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



def FormatDateForDB(input) 
    defaultDate = "1753-01-01"
    #  TODO: add test for 'useCurrent' and the associated logic.
    if input == 'useCurrent'
       t = Time.current 
       output = t.strftime("%Y-%m-%d") 
    elsif  input == nil || input == ''  
       output = defaultDate
    else
       # 01012022 or 010122
       w = input.to_s
       m = w[0..1]
       d = w[2..3]
       length = w.length
       if length == 8 
          y = w[4..7]
       else
          a = w[4..5]
          ay = a.to_i
          nextYear = 23
          if ay > 23 
            y = "19" + a
          else
            y = "20" + a
          end
       end
       dash = "-"  
       output = y + dash + m + dash + d 
    end 
    return output

end 
 
  
 def FormatDateForScreen(input)
 
       
   if input == nil  
      local = Date.new(2022,01,02)
      return local
   end
   # copy of update code when loading screen that works!
   birth = input.to_s 
   d = birth[8,2].to_i
   m = birth[5,2].to_i
   y = birth[0,4].to_i  
   if y == 1753 || y == 1900 then
      localCustBirthDate = nil
   else
      localCustBirthDate = Date.new(y,m,d) 
   end  
   return localCustBirthDate
 end

 
 def FormatForDB(inputDate)

   if inputDate == nil || inputDate == "" then
      dDate = "1753-01-01"
      return dDate
   end

   # format is yyyy-mm-dd from the control.
   iy = inputDate[0..3]
   im = inputDate[5..6]
   id = inputDate[8..9] 
   dash = "-"

   dbDate = iy + dash + im + dash + id
   return dbDate

end
    
    private
    
    def claim_params
    
      params.require(:claim)
            .permit(:ClaimDescription, :PlanId, :PatientFirst, :PatientLast,
                    :Diagnosis1, :Diagnosis2,:Procedure1,:Procedure2,:Physician, 
                    :DateService,  :Referral, :Clinic, :Service,
                    :DateConfine,  :DateRelease,
                    :ToothNumber, :Eyeware, :DrugName)
    
    end
    
    end
    
      
    
  
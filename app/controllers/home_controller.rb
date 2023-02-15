class HomeController < ApplicationController
    def start
  
      # when come from anywhre signout - used from main menu
      session[:signin] == ""
      session[:custId] == ""
  
      #todo: investigate time zone for west coast time.
      timeNow = Time.current
      @displayTime = timeNow.strftime("%-I:%M %p %A %B %d %Y") 
  
    end 
    
  def notSignedIn
  
    # prevent unauthorized access
    checkForYes = session[:signin]
    if checkForYes == "yes" then
       return false 
    end  
    return true
   end
    
    def classic 
    end
    def about
    end
    def menu  
      
        if notSignedIn() then
          redirect_to controller: :customers, action:  :notauthorized 
          return
        end
 
  
        # display any flash messages.
        sentMessage = flash[:message]
        if sentMessage != nil then 
           @message = sentMessage 
           flash[:message] = nil
        end
 
  
    end
    def info
    end
  
    def notauthorized
    end

    def index
    end

    
  
    def log(value) 
  
      # comment this out in production 
      require 'logger'
  
      logger.debug(value)
  
    end
    
  end
  

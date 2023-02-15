
class Customer

    attr_accessor :custId, :custPassword, :Encrypted, :custFirst, :custMiddle, :custLast, 
                  :custPhone, :custEmail, :custGender, :custAddr1, :custAddr2,
                  :custCity, :custState, :custZip, :custBirthDate, :custPlan,
                  :PromotionCode, 
                  :confirm, :extendColors,
                  :appId, :claimCount,
                  :Id,
                  :_csrf

    # signin initialize
    def initialize()

        @custId = ""
        @custPassword = ""


    end 

    def read(a)

        return a.to_json.to_s

    end
 

    # register initialize
    


end
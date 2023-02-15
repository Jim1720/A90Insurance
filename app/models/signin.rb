class Signin  

    attr_accessor :custId, :custPassword
    # https://www.bootrails.com/blog/ruby-attr-accessor-attr-writer-attr-reader/

    def initialize(custId, custPassword)

        @custId = custId
        @custPassword = custPassword

    end

    def initialize()

        @custId = ""
        @custPassword = ""

    end

end

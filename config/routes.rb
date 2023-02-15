Rails.application.routes.draw do
  get 'customers/register'
  get 'home/start'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

# proceed to start when app begins

# since i did not ues resources...
# ref: https://findnerd.com/list/view/Rails-Using-forms-for-operations-like-Patch-Put--Delete/5738/
# <input name="_method" type="hidden" value="patch" />
# must be included in the update form.


root "home#start" 

get "/", to: "home#start"

get "/classic", to: "home#classic"

get "/about",    to: "home#about"

get "/register",  to: "customers#register"   

post "/customers", to: "customers#registercustomer"

get "/signin", to: "customers#signin"

post "/signincustomer", to: "customers#signincustomer" 

get "/menu", to: "home#menu"

get "/update", to: "customers#update" 

# form uses POST but magic changes it to PATCH.
patch "/processupdate", to: "customers#processupdate"   

#  using post for api call it uses put 
 
get "/signout", to: "customers#signout" 

get "/info", to: "home#info" 

get "/plan", to: "customers#plan" 
patch "/plan", to: "customers#plan"

get "/claim", to: "claim#claim" 

# new
post "/claimadd", to: "claim#claimadd"
# adj
patch "/claimadd", to: "claim#claimadd"

get "/history", to: "claim#history" 
patch "/historynext", to: "claim#historynext"

get "/notauthorized", to: "customers#notauthorized" 

get "/payment", to: "claim#payment" 

# form uses POST but magic changes it to PATCH.
patch "/payclaim", to: "claim#payclaim"   
 
# for azure pings 
get "/robots933456.txt", to: "home#index"

# administration routes

get "/admin", to: "admin#admin"

post "/adminsignin", to: "admin#adminsignin" 


get "/action", to: "admin#action"

post "/actionresponse", to: "admin#actionresponse" 

get "/customerlist", to: "admin#customerlist"

end



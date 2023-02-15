

FROM ruby:3.1.3 
 

# Source: Jan3 Sky prototype.
# use vethernet ip ipV4 used by WSL - see ipconfig.
 

  # a45 with docker ip.

  # local a45 prefix
  # ENV A90UrlPrefix="http://172.31.128.1:3200"

  # azure a45 prefix
  ENV A90UrlPrefix="https://azureprefix"

   
  ENV A90PromotionCode=100 
  ENV A90UseApiCalls=Yes
  ENV A90AdmId=adm 
  ENV A90AdmPass=wow 

  ENV RAILS_ENV=production
  ENV RAILS_SERVE_STATIC_FILES=true


# docker build -t a90insurance:feb7b .

# docker run  -tp 3000:3000 a90insurance:feb7b


 
# =========== azure environment settings ============================  
# set PORT to 8080
# =====================================================================
 
 
LABEL Name=blog Version=1.0.0
 

RUN apt-get update && apt-get install -y npm && npm install -g yarn

WORKDIR /app
COPY . /app/


RUN gem install bundler  

RUN bundle install  
RUN yarn install
 
ENTRYPOINT ["rails","server","-b","0.0.0.0"] 

EXPOSE 3000
 
FOR /F "tokens=*" %%i IN (..\.env) DO set %%i
set COSMOS_REDIS_HOSTNAME=127.0.0.1
call bundle install
call bundle exec rails s

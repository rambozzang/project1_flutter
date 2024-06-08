#!/bin/bash
# api key : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0eWV1eW5yYXBiZ3RwcXV4eGZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc1NTM4NzYsImV4cCI6MjAzMzEyOTg3Nn0.RZKF6Nfkqr7fA7Uc7RtZc_Jnl4zw_Q6iDV-5J9DfIM8
# prepare.sh -h "https://wtyeuynrapbgtpquxxfm.supabase.co" -p your-postgres-port -d "your-postgres-database-name" -U "your-postgres-user"

# https://supabase.com/dashboard/project/wtyeuynrapbgtpquxxfm/settings/database 에서 확인 가능.
# ./prepare.sh  -h "https://aws-0-ap-northeast-2.pooler.supabase.com" -p "6543" -d "postgres" -U "postgres.wtyeuynrapbgtpquxxfm"
# ./prepare.sh  -h aws-0-ap-northeast-2.pooler.supabase.com -p 6543 -d postgres -U postgres.wtyeuynrapbgtpquxxfm

# psql 설치  : brew install libpq
# DB 접속 비밀번호  : GsH1yDz1ZytaChAS  
while getopts h:p:d:U flag
do
    case "${flag}" in
        h) hostname=${OPTARG};;
        p) port=${OPTARG};;
        d) database=${OPTARG};;
        U) user=${OPTARG};;
    esac
done

psql -U $user -h $hostname -p $port -d $database -f ./sql/01_database_schema.sql
psql -U $user -h $hostname -p $port -d $database -f ./sql/02_database_trigger.sql
psql -U $user -h $hostname -p $port -d $database -f ./sql/03_database_policy.sql
psql -U $user -h $hostname -p $port -d $database -f ./sql/04_storage.sql


PGPASSWORD=GsH1yDz1ZytaChAS psql -h aws-0-ap-northeast-2.pooler.supabase.com -p 6543 -d postgres -U postgres.wtyeuynrapbgtpquxxfm -f ./sql/01_database_schema.sql        
PGPASSWORD=GsH1yDz1ZytaChAS psql -h aws-0-ap-northeast-2.pooler.supabase.com -p 6543 -d postgres -U postgres.wtyeuynrapbgtpquxxfm -f ./sql/02_database_trigger.sql        
PGPASSWORD=GsH1yDz1ZytaChAS psql -h aws-0-ap-northeast-2.pooler.supabase.com -p 6543 -d postgres -U postgres.wtyeuynrapbgtpquxxfm -f ./sql/03_database_policy.sql        
PGPASSWORD=GsH1yDz1ZytaChAS psql -h aws-0-ap-northeast-2.pooler.supabase.com -p 6543 -d postgres -U postgres.wtyeuynrapbgtpquxxfm -f ./sql/04_storage.sql       


psql -h aws-0-ap-northeast-2.pooler.supabase.com -p 6543 -d postgres -U postgres.wtyeuynrapbgtpquxxfm -f ./sql/01_database_schema.sql
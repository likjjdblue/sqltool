#!/bin/bash

#db_root_user='root'
#db_root_passwd='abc123'
db_host=${db_host-mysql}
#
#db_name='db_foo'
#db_user='foo'
#db_user_passwd='!QAZ2wsx1234'
#
#mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "CREATE DATABASE ${db_name} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
#mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "grant all privileges on ${db_name}.* to ${db_user}@'%' identified by '${db_user_passwd}'"


function create_db_and_user
{
   db_name=$1
   db_user=$2
   db_user_passwd=$3

   echo "create ${db_name} ${db_user} ${db_user_passwd}"

   mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "CREATE DATABASE ${db_name} /*\!40100 DEFAULT CHARACTER SET utf8 */;";true
   mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "grant all privileges on ${db_name}.* to ${db_user}@'%' identified by '${db_user_passwd}'";true
}


function check_db_exists
{
   db_name=$1
   mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "use ${db_name}"
   echo "$?"
}

function check_db_table_num
{
  db_name=$1
  total_table_num=$(mysql -sN -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "select count(*) from information_schema.tables where table_schema='${db_name}'")
  echo ${total_table_num}
}

function check_mysql_server_connection
{
   for (( i=0;i<=20;i++ ))
   do
     mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} -e "status;"  >/dev/null 2>&1
     ret_code=$?
     echo "return code ${ret_code}" 

     if [[ "$?" != "0" ]]
     then
        echo "尝试连接 MYSQL服务器：${db_host},第${i} 次"
        
        sleep 2

        if [[ ${i} == '20' ]]
        then
            echo "连接mysql 超时，程序退出"
            exit 1
        fi

        continue
     fi
     break
   done
}


function load_sql
{
  sql_filepath=$1
  sql_filename=$(basename ${sql_filepath})

#  target_db_name=$(echo "${sql_filename}"|awk -F '_' '{print $1}')
  target_db_name=$(echo "${sql_filename}"|awk -F '.sql' '{print $1}')
  
  if [ -z "${target_db_name}" ]
  then
     echo "错误： 无法提取 ${sql_filename} 中的database 名称,无法导入SQL，程序退出！"
     exit 1
  fi

  is_db_exist=$(check_db_exists ${target_db_name}) 
  if [[ "${is_db_exist}" != '0' ]]
  then
     echo "错误：${target_db_name} 库不存在，程序退出"
     exit 1    
  fi 


  tmp_total_table_num=$(check_db_table_num ${target_db_name})
  if [[ "${tmp_total_table_num}" != "0" ]]
  then
     echo "警告：${target_db_name} 库非空，跳过导入SQL，${sql_filepath}"
     exit 1  
  fi

  mysql -h ${db_host} -u ${db_root_user} -p${db_root_passwd} ${target_db_name} <${sql_filepath}
 
  if [[ "$?" != '0' ]]
  then
     echo "错误：导入${sql_filename} 失败，程序退出"
     exit 1
  fi  

}


###获取root 账号信息
while read line
do
   if [[ -z "${line}" ]]
   then
      continue
   fi

   tmp_db_name=$(echo "${line}"|awk '{print $1}')
   tmp_db_user=$(echo "${line}"|awk '{print $2}')
   tmp_user_passwd=$(echo "${line}"|awk '{print $3}')

   if [[ ${tmp_db_user} == "root" ]]
   then
      db_root_user='root'
      db_root_passwd=${tmp_user_passwd}
   fi
done<account/account.txt

echo "db_root:${db_root_user}"
echo "db_root_pass:${db_root_passwd}"

### 创建库，用户
while read line
do
   if [[ -z "${line}" ]]
   then
      continue
   fi

   tmp_db_name=$(echo "${line}"|awk '{print $1}')
   tmp_db_user=$(echo "${line}"|awk '{print $2}')
   tmp_user_passwd=$(echo "${line}"|awk '{print $3}')

   if [[ ${tmp_db_user} != "root" ]]
   then
      check_mysql_server_connection
      create_db_and_user ${tmp_db_name} ${tmp_db_user}  ${tmp_user_passwd}     
   fi
done<./account/account.txt



###导入SQL
find `pwd`/sql -mindepth 1 -maxdepth 1 -type f|while read line;do
   load_sql ${line}
done




















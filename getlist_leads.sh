#!/bin/bash
#Get all accounts
#curl -g -b ./amocrm.cookies "https://example.amocrm.ru/api/v2/account?with=users&free_users=Y" > accounts.txt

ifmodifiedsince=$1

find_keys_with_value()
{
    local json_keys=${@}
    for key in ${json_keys[@]}; do
        local key_type=$(echo $current_root_json |jq -r "$key|type")
        if [[ "$key_type" = "object" ]]
        then
        	local full_path_include_keys=()
            local include_keys=$(echo $current_root_json | jq -r "$key|keys[]")
            for include_key in ${include_keys[@]}; do
                if [[ "$key" = "." ]]
                then
                    full_path_include_keys+=( "$key$include_key" )
                else
                    full_path_include_keys+=( "$key.$include_key" )
                fi
            done
            find_keys_with_value ${full_path_include_keys[@]}
        else
            non_object_keys+=( $key )
        fi
    done
}

convert_json_to_sql()
{
	local F_LEADS=$1
	local F_SQL_LEADS=sqlloadleads.sql.$F_LEADS
	declare -i count_leads=$(jq -r '._embedded.items|keys|length' $F_LEADS)
    for ((i=0;i<count_leads;i++)); do
	    local root_keys=()
	    root_keys+=( "._embedded.items[$i]" )
	    local all_keys_with_value=()
	    local non_object_keys=()
        local start_key=()
        start_key+=( "." )
        local current_root_json=$(jq -r ${root_keys[0]} $F_LEADS)
	    find_keys_with_value ${start_key[@]}
	    local sql_insert_begin='INSERT INTO amocrm_leads ('
        local sql_insert_end=') VALUES ('
        local sql_insert_update=') ON DUPLICATE KEY UPDATE '
        local length_of_keys=$(expr ${#non_object_keys[@]} - 1)
	    for index_of_keys in ${!non_object_keys[@]}; do
		    local found_key=${non_object_keys[index_of_keys]}
    	    local key_name=$(echo ${found_key##*].}| sed 's/^\.//g'|sed 's/\./$/g')
    	    local value_of_key=$(echo $current_root_json | jq -r "$found_key" | sed 's/\"/\\\"/g'| sed "s/'/\\\'/g")
    	    if [[ index_of_keys -lt length_of_keys ]]
    	    then
        	    sql_insert_begin+="$key_name,"
        	    sql_insert_end+="'$value_of_key',"
        	    if [[ "$key_name" != "id" ]]
        	    then
        	        sql_insert_update+="$key_name='$value_of_key',"
        	    fi
    	    else
        	    sql_insert_begin+="$key_name"
        	    sql_insert_end+="'$value_of_key'"
        	    if [[ "$key_name" != "id" ]]
        	    then
        	        sql_insert_update+="$key_name='$value_of_key';"
        	    else
                    sql_insert_update+=";"
        	    fi
    	    fi
        done
        echo $sql_insert_begin $sql_insert_end $sql_insert_update >> $F_SQL_LEADS
    done
}

F_SQL_LEADS=sqlloadleads.sql
FS_LEADS=()
repeat_loop_curl_leads=1
respose_status=$(curl -c ./amocrm.cookies --silent --write-out %{http_code} --output /dev/null "https://example.amocrm.ru/private/api/auth.php?USER_LOGIN=admin@exmaple.kz&USER_HASH=eeeeeeeddddddd")
if [[ $respose_status -ne 200 ]]
then
   exit 1
fi
if [[ -n $ifmodifiedsince ]]
then
    DATE=$(date -u -d @$ifmodifiedsince +%a,\ %d\ %b\ %Y\ %H:%M:%S\ UTC)
fi
declare -i offset=0
while (( repeat_loop_curl_leads )); do
	if [[ -n $ifmodifiedsince ]]
	then
	    respose_status=$(curl -g -b ./amocrm.cookies -H "If-Modified-Since: $DATE" -H "Accept: application/json" --silent --write-out %{http_code} --output tmp_leads_file.json "https://example.amocrm.ru/api/v2/leads?type=lead&limit_rows=500&limit_offset=$(expr 500 \* $offset)")
    else
        respose_status=$(curl -g -b ./amocrm.cookies -H "Accept: application/json" --silent --write-out %{http_code} --output tmp_leads_file.json "https://example.amocrm.ru/api/v2/leads?type=lead&limit_rows=500&limit_offset=$(expr 500 \* $offset)")
    fi
	if [[ $respose_status -eq 200 ]]
	then
        ascii2uni -a U -q tmp_leads_file.json > leads_file_$offset.json
        FS_LEADS+=( leads_file_$offset.json )
    else
    	repeat_loop_curl_leads=0
	fi
	offset+=1
done
rm -f tmp_leads_file.json
echo -n > $F_SQL_LEADS
child_pid=()
for F_LEADS in ${FS_LEADS[@]}; do
	if [[ -e $F_LEADS ]]
	then
       convert_json_to_sql $F_LEADS &
    fi
    child_pids+=( $! )
done
for child_pid in ${child_pids[@]}; do
    wait $child_pid
done
echo -n > $F_SQL_LEADS
for F_LEADS in ${FS_LEADS[@]}; do
    cat $F_SQL_LEADS.$F_LEADS >> $F_SQL_LEADS
    rm -f $F_SQL_LEADS.$F_LEADS
done
rm -f ${FS_LEADS[*]}
mysql -pdbpassword -u root asteriskcdrdb < $F_SQL_LEADS

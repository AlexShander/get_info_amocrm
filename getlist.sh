#!/bin/bash
#Get all accounts
#curl -g -b ./amocrm.cookies "https://example.amocrm.ru/api/v2/account?with=users&free_users=Y" > accounts.txt

find_keys_with_value()
{
    local json_keys=${@}
    for key in ${json_keys[@]}; do
        local key_type=$(jq -r "$key|type" $F_NOTES)
        if [[ "$key_type" = "object" ]]
        then
        	local full_path_include_keys=()
            local include_keys=$(jq -r "$key|keys[]" $F_NOTES)
            for include_key in ${include_keys[@]}; do
                full_path_include_keys+=( "$key.$include_key" )
            done
            find_keys_with_value ${full_path_include_keys[@]}
        else
            non_object_keys+=( $key )
        fi
    done
}

F_SQL_NOTES=sqlloadnotes.sql
FS_NOTES=()
repeat_loop_curl_notes=1
respose_status=$(curl -c ./amocrm.cookies --silent --write-out %{http_code} --output /dev/null "https://example.amocrm.ru/private/api/auth.php?USER_LOGIN=admin@example.kz&USER_HASH=eeeeeeeeddddddd")
if [[ $respose_status -ne 200 ]]
then
   exit 1
fi
declare -i offset=0
while (( repeat_loop_curl_notes )); do
	respose_status=$(curl -g -b ./amocrm.cookies --silent --write-out %{http_code} --output tmp_notes_file.json "https://example.amocrm.ru/api/v2/notes?type=lead&limit_rows=500&limit_offset=$(expr 500 \* $offset)")
	if [[ $respose_status -eq 200 ]]
	then
        ascii2uni -a U -q tmp_notes_file.json > notes_file_$offset.json
        FS_NOTES+=( notes_file_$offset.json )
    else
    	repeat_loop_curl_notes=0
	fi
	offset+=1
done
rm -f tmp_notes_file.json
echo -n > $F_SQL_NOTES
for F_NOTES in ${FS_NOTES[@]}; do
    declare -i count_notes=$(jq -r '._embedded.items|keys|length' $F_NOTES)
    for ((i=0;i<count_notes;i++)); do
	    root_keys=()
	    root_keys+=( "._embedded.items[$i]" )
	    all_keys_with_value=()
	    non_object_keys=()
	    find_keys_with_value ${root_keys[@]}
	    sql_insert_begin='INSERT INTO amocrm_notes ('
        sql_insert_end=') VALUES ('
        length_of_keys=$(expr ${#non_object_keys[@]} - 1)
	    for index_of_keys in ${!non_object_keys[@]}; do
		    found_key=${non_object_keys[index_of_keys]}
    	    key_name=$(echo ${found_key##*].}| sed 's/\./$/g')
    	    value_of_key=$(jq -r "$found_key" $F_NOTES)
    	    if [[ index_of_keys -lt length_of_keys ]]
    	    then
        	    sql_insert_begin+="\"$key_name\","
        	    sql_insert_end+="\"$value_of_key\","
    	    else
        	    sql_insert_begin+="\"$key_name\""
        	    sql_insert_end+="\"$value_of_key\");"
    	    fi
        done
        echo $sql_insert_begin $sql_insert_end >> $F_SQL_NOTES
    done
done
rm -f ${FS_NOTES[@]}

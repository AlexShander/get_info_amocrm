# get_info_amocrm
Copy issues, notes, deals to mysql for Grafana.

You must to changeL
example
admin@example.kz
hash=eeedddd....

to your real credentials.

# How to use
For example you can handle through crontab
<   #Grafana gets JSON via API >
<   10 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_leads.sh $(expr $(date +%s) - 3600 )
<   30 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_leads.sh $(expr $(date +%s) - 3600 )
<   50 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_leads.sh $(expr $(date +%s) - 3600 ) 
<   
<   15 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_notes.sh $(expr $(date +%s) - 3600 )
<   35 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_notes.sh $(expr $(date +%s) - 3600 )
<   55 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_notes.sh $(expr $(date +%s) - 3600 )
<   
<   20 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_tasks.sh $(expr $(date +%s) - 3600 )
<   40 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_tasks.sh $(expr $(date +%s) - 3600 )
<   0 * * * * cd /usr/local/amocrm/grafana_sql/ && /usr/local/amocrm/grafana_sql/getlist_tasks.sh $(expr $(date +%s) - 3600 )

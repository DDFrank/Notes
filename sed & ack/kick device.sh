curl -u c1dddc67ea826:MjkwMjUyNTEwODcxNjQxNDU3NTE4OTk5MjkxMjMyOTExMzG http://localhost:7180/api/v3/nodes/emqx@172.20.1.28/connections/ | jq .data[].client_id > clients

sed "s/\"//g" clients

cat clients | xargs -I {} curl -u c1dddc67ea826:MjkwMjUyNTEwODcxNjQxNDU3NTE4OTk5MjkxMjMyOTExMzG -X DELETE http://localhost:7180/api/v3/connections/{}
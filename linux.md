# 以下命令适用于 RECH7.0
## 永久去掉密钥交换
出现这样的提示的时候
The authenticity of host '172.16.224.97 (127.0.0.1)' can't be established.

修改/etc/ssh/ssh_config文件（或$HOME/.ssh/config）中的配置
最后添加两行
StrictHostKeyChecking no
UserKnownHostsFile /dev/null

重新启动ssh服务
systemctl restart sshd.service

## 守护进程方式开启，并重定向输出到文件
nohup java -jar yourackage-version.jar >temp.log & 

## 查看自己是红帽哪个版本
cat /etc/redhat-release

## CURL命令

```
curl -H 'Content-Type: application/json' -XPUT http://127.0.0.1:9200/tran_news -d '
{

  "settings":{
    
    "number_of_shards": 3,
    
    "number_of_replicas": 1

  },
   "mappings": {
      "doc": {
        "properties": {
          "id": {
            "type": "integer"
          },
          "news_type": {
            "type": "integer"
          },
          "title": {
            "type": "text"
          },
           "list_img": {
            "type": "text"
          },
          "origin": {
            "type": "text"
          },
          "editor": {
            "type": "text"
          },
          "content": {
            "type": "text"
          },
          "lang_id": {
            "type": "integer"
          },
           "life_status": {
            "type": "integer"
          },
           "publish_date": {
             "type": "date",
            "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
          },
          "create_user": {
            "type": "integer"
          },
          "create_time": {
            "type": "date",
            "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
          },
          "modify_user": {
            "type": "integer"
          },
          "modify_time": {
            "type": "date",
            "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
          }
        }
      }
    }
}
'

```
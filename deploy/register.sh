# get appmgr http ip
httpAppmgr=$(kubectl get svc -n ricplt | grep service-ricplt-appmgr-http | awk '{print $3}') 

# for delete the register by curl
curl -X POST "http://${httpAppmgr}:8080/ric/v1/deregister" -H "accept: application/json" -H "Content-Type: application/json" -d '{"appName": "kpimon-go", "appInstanceName": "kpimon-go"}'

# for delete the registration which is registered after xapp is enabled (kpimon-go uses null appInstanceName to register)
curl -X POST "http://${httpAppmgr}:8080/ric/v1/deregister" -H "accept: application/json" -H "Content-Type: application/json" -d '{"appName": "kpimon-go", "appInstanceName": ""}'

# get xapp http ip
httpEndpoint=$(kubectl get svc -n ricxapp | grep 8080 | awk '{print $3}')
# get xapp rmr ip
rmrEndpoint=$(kubectl get svc -n ricxapp | grep 4560 | awk '{print $3}')

# do register
curl -X POST "http://${httpAppmgr}:8080/ric/v1/register" -H "accept: application/json" -H "Content-Type: application/json" -d '{"appName": "kpimon-go", "appVersion": "2.0.2-alpha", "configPath": "", "appInstanceName": "kpimon-go", "httpEndpoint": "${httpEndpoint}:8080", "rmrEndpoint": "${rmrEndpoint}:4560", "config": "{\"name\": \"kpimon-go\", \"xapp_name\": \"kpimon-go\", \"version\": \"2.0.2-alpha\", \"containers\": [{\"name\": \"kpimon-go\", \"image\": {\"registry\": \"127.0.0.1:5000\", \"name\": \"o-ran-sc/ric-app-kpimon-go\", \"tag\": \"latest\" }}], \"livenessProbe\": {\"httpGet\": {\"path\": \"ric/v1/health/alive\", \"port\": 8080 }, \"initialDelaySeconds\": 5, \"periodSeconds\": 15 }, \"readinessProbe\": {\"httpGet\": {\"path\": \"ric/v1/health/ready\", \"port\": 8080 }, \"initialDelaySeconds\": 5, \"periodSeconds\": 15 }, \"messaging\": {\"ports\": [{\"name\": \"http\", \"container\": \"kpimon-go\", \"port\": 8080, \"description\": \"http service\" }, {\"name\": \"rmr-data\", \"container\": \"kpimon-go\", \"port\": 4560, \"rxMessages\": [\"RIC_SUB_RESP\", \"RIC_INDICATION\"], \"txMessages\": [\"RIC_SUB_REQ\"], \"policies\": [], \"description\": \"rmr receive data port for xappkpimon\" }, {\"name\": \"rmr-route\", \"container\": \"kpimon-go\", \"port\": 4561, \"description\": \"rmr route port for xappkpimon\" }] }, \"rmr\": {\"protPort\": \"tcp:4560\", \"maxSize\": 2072, \"numWorkers\": 1, \"rxMessages\": [\"RIC_SUB_RESP\", \"RIC_INDICATION\"], \"txMessages\": [\"RIC_SUB_REQ\"], \"policies\": [] }}"}'

# rollback xapp
kubectl rollout restart deployment --namespace ricxapp ricxapp-kpimon-go

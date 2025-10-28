#!/bin/bash
#set -x
IMAGE="maprtech/dev-sandbox-container:latest"
INTERFACE="en0"

usage()
{
   echo "This script will deploy edf on sandbox-container."
   echo
   echo "Syntax: ./mapr_devsandbox_container_setup.sh [-image] [-nwinterface]"
   echo "options:"
   echo "-image this is optional,By default it will pull image having latest tag,
         we can also provide image which has custom tag example:maprtech/dev-sandbox-container:7.10.0_9.4.0_ubuntu20"
   echo "-nwinterface is optional,By default it will use en0 network interface. To use a host network interface other than en0 for the container, specify the interface name"
   echo
}

while [ $# -gt 0 ]
do
  case "$1" in
  -image) shift; IMAGE=$1;;
  -nwinterface) shift; INTERFACE=$1;;
  *) shift;
   usage
   exit;;
   esac
   shift
done

os_vers=`uname -s` > /dev/null 2>&1

which ipconfig
if [ $? -eq 0 ]; then
  IP=$(ipconfig getifaddr $INTERFACE)
else
  IP=$(ip addr show $INTERFACE | grep -w inet | awk '{ print $2}' | cut -d "/" -f1)
fi
clusterName="${clusterName:-"maprdemo.mapr.io"}"
hostName=$(echo ${clusterName} | cut -d '.' -f 1)

#check if ports used by Sandbox is already used by some other process

port_available=1
docker ps -q > /dev/null 2>&1
if [ $? == 0 ]; then

# Define the ports you want to check

ports=(9998 8042 8888 8088 9997 10001 8190 8243 2222 4040 7221 8090 5660 8443 19888 50060 18080 8032 14000 19890 10000 11443 12000 8081 8002 8080 31010 8044 8047 11000 2049 8188 7077 7222 5181 5661 5692 5724 5756 10020  9001 5693 9002 31011)


# Loop through each port and check if it's in use
for port in "${ports[@]}"; do

    # Check if port is in use by any container, and exclude containers with "dev-sandbox-container" in the image name

        if [[ "$os_vers" == "Darwin" ]]; then
            # macOS: use lsof
            port_in_use=$(lsof -nP -iTCP -sTCP:LISTEN | grep ":$port" | awk '{print $2}' | head -n 1)
        else
            # Linux: use ss
            port_in_use=$(ss -tulnp | grep ":$port " | awk '{print $6}' | cut -d',' -f2)
        fi

    if [[ -n "$port_in_use" ]]; then
        # Get the container ID using that port
        container_using_port=$(docker ps -q --filter "publish=$port")

        # Check if the container is excluded (based on image name containing "dev-sandbox-container")
        container_image=$(docker ps -a --filter "id=$container_using_port" --format "{{.Image}}")

        if [[ "$container_image" == *"dev-sandbox-container"* ]]; then
            port_available=1
        else
            echo "Please check port availability as Port $port is in use by container $container_using_port with image '$container_image'."
            port_available=0
            exit 1
        fi
    else
        port_available=1
    fi
done
fi

runMaprImage() {
    echo "Please enter the local sudo password for $(whoami)"
        sudo rm -rf /tmp/maprdemo
        sudo mkdir -p /tmp/maprdemo/hive /tmp/maprdemo/zkdata /tmp/maprdemo/pid /tmp/maprdemo/logs /tmp/maprdemo/nfs
        sudo chmod -R 777 /tmp/maprdemo/hive /tmp/maprdemo/zkdata /tmp/maprdemo/pid /tmp/maprdemo/logs /tmp/maprdemo/nfs


        PORTS='-p 9998:9998 -p 8042:8042 -p 8888:8888 -p 8088:8088 -p 9997:9997 -p 10001:10001 -p 8190:8190 -p 8243:8243 -p 2222:22 -p 4040:4040 -p 7221:7221 -p 8090:8090 -p 5660:5660 -p 8443:8443 -p 19888:19888 -p 50060:50060 -p 18080:18080 -p 8032:8032 -p 14000:14000 -p 19890:19890 -p 10000:10000 -p 11443:11443 -p 12000:12000 -p 8081:8081 -p 8002:8002 -p 8080:8080 -p 31010:31010 -p 8044:8044 -p 8047:8047 -p 11000:11000 -p 2049:2049 -p 8188:8188 -p 7077:7077 -p 7222:7222 -p 5181:5181 -p 5661:5661 -p 5692:5692 -p 5724:5724 -p 5756:5756 -p 10020:10020  -p 9001:9001 -p 5693:5693 -p 9002:9002 -p 31011:31011'

        #export MAPR_EXTERNAL="0.0.0.0"
  #incase non-mac ipconfig command would not be found
  which ipconfig
  if [ $? -eq 0 ]; then
    export MAPR_EXTERNAL=$(ipconfig getifaddr $INTERFACE)
  else
    export MAPR_EXTERNAL=$(ip addr show $INTERFACE | grep -w inet | awk '{ print $2}' | cut -d "/" -f1)
  fi
        #echo $MAPR_EXTERNAL

  if [ "${IMAGE}" == "maprtech/dev-sandbox-container:latest" ]; then docker pull ${IMAGE}; fi
        docker run -d --privileged -v /tmp/maprdemo/zkdata:/opt/mapr/zkdata -v /tmp/maprdemo/pid:/opt/mapr/pid  -v /tmp/maprdemo/logs:/opt/mapr/logs  -v /tmp/maprdemo/nfs:/mapr $PORTS -e MAPR_EXTERNAL -e clusterName -e isSecure --hostname ${clusterName} ${IMAGE} > /dev/null 2>&1

   # Check if docker container is started wihtout any issue
   sleep 5 # wait for docker container to start

    CID=$(docker ps -a | grep dev-sandbox-container | awk '{ print $1 }' )
    RUNNING=$(docker inspect --format="{{.State.Running}}" $CID 2> /dev/null)
    ERROR=$(docker inspect --format="{{.State.Error}}" $CID 2> /dev/null)

    if [ "$RUNNING" == "true" -a "$ERROR" == "" ]
    then
            echo "Developer Sandbox Container $CID is running.."
    else
            echo "Failed to start Developer Sandbox Container $CID. Error: $ERROR"
            exit
    fi
}

docker ps -a | grep dev-sandbox-container > /dev/null 2>&1
if [ $? -ne 0 ]
then
        STATUS='NOTRUNNING'
else
        echo "MapR sandbox container is already running."
        echo "1. Kill the earlier run and start a fresh instance"
        echo "2. Reconfigure the client and the running container for any network changes"
        echo -n "Please enter choice 1 or 2 : "
        read ANS
        if [ "$ANS" == "1" ]
        then
                CID=$(docker ps -a | grep dev-sandbox-container | awk '{ print $1 }' )
                docker rm -f $CID > /dev/null 2>&1
                STATUS='NOTRUNNING'
        else
                STATUS='RUNNING'
        fi
fi

if [ "$STATUS" == "RUNNING" ]
then
        # There is an instance of dev-sandbox-container. Check if it is running or not.
        CID=$(docker ps -a | grep dev-sandbox-container | awk '{ print $1 }' )
        RUNNING=$(docker inspect --format="{{.State.Running}}" $CID 2> /dev/null)
        if [ "$RUNNING" == "true" ]
        then
                # Container is running there.
                # Change the IP in /etc/hosts and reconfigure client for the IP Change
                # Change the server side settings and restart warden
                grep maprdemo /etc/hosts | grep ${IP} > /dev/null 2>&1
                if [ $? -ne 0 ]
                then
                        echo "Please enter the local sudo password for $(whoami)"
                        sudo sed -i '' '/maprdemo/d' /etc/hosts &>/dev/null
                        sudo  sh -c "echo  \"${IP}      ${clusterName}  ${hostName}\" >> /etc/hosts"
                        sudo sed -i '' '/maprdemo/d' /opt/mapr/conf/mapr-clusters.conf
            sudo /opt/mapr/server/configure.sh -c -C ${IP}  -N ${clusterName} > /dev/null 2>&1
                        # Change the external IP in the container
                        echo "Please enter the root password of the container 'mapr' "
                        ssh root@localhost -p 2222 " sed -i \"s/MAPR_EXTERNAL=.*/MAPR_EXTERNAL=${IP}/\" /opt/mapr/conf/env.sh "
                        echo "Please enter the root password of the container 'mapr' "
                        ssh root@localhost -p 2222 "service mapr-warden restart"
                fi
        fi
        if [ "$RUNNING" == "false" ]
        then
                # Container was started earlier but is not running now.
                # Start the container. Change the client side settings
                # Change the server side settings
                docker start ${CID}
                echo "Please enter the local sudo password for $(whoami)"
                sudo sed -i '' '/maprdemo/d' /etc/hosts &>/dev/null
                sudo sh -c "echo  \"${IP}       ${clusterName}  ${hostName}\" >> /etc/hosts"
                sudo sed -i '' '/maprdemo/d' /opt/mapr/conf/mapr-clusters.conf
        sudo /opt/mapr/server/configure.sh -c -C ${IP}  -N ${clusterName} > /dev/null 2>&1
        # Change the external IP in the container
                echo "Please enter the root password of the container 'mapr' "
                ssh root@localhost -p 2222 " sed -i \"s/MAPR_EXTERNAL=.*/MAPR_EXTERNAL=${IP}/\" /opt/mapr/conf/env.sh "
                echo "Please enter the root password of the container 'mapr' "
        ssh root@localhost -p 2222 "service mapr-warden restart"
        fi
else
        # There is no instance of dev-sandbox-container running. Start a fresh container and configure client.
        runMaprImage

        sudo /opt/mapr/server/configure.sh -c -C ${IP}  -N ${clusterName} > /dev/null 2>&1
        sudo sed -i '' '/maprdemo/d' /etc/hosts &>/dev/null
        sudo  sh -c "echo  \"${IP}      ${clusterName}  ${hostName}\" >> /etc/hosts"

        services_up=0
        sleep_total=600
        sleep_counter=0
        if [ "$os_vers" == "Darwin" ]; then
           while [[ $sleep_counter -le $sleep_total ]]
            do

             curl -k -X GET "https://maprdemo.mapr.io:8443/rest/node/list?columns=svc" -u mapr:mapr &>/dev/null

             if [ $? -ne 0 ];then
                echo "services required for HPE Data fabric are  coming up"
                sleep 60;
                sleep_counter=$((sleep_counter+60))
             else
                services_up=1
                break
             fi
           done
       fi
       if [ "$os_vers" == "Linux" ]; then
           while [[ $sleep_counter -le $sleep_total ]]
            do

             curl -k -X GET https://`hostname -f`:8443/rest/node/list?columns=svc -u mapr:mapr &>/dev/null

             if [ $? -ne 0 ];then
                echo "services required for HPE Data fabric are  coming up"
                sleep 60;
                sleep_counter=$((sleep_counter+60))
             else
                services_up=1
                break
             fi
           done
       fi

        if [ $services_up -eq 1 ]; then

           echo
           echo "Docker Container is up and running...."
           echo "Mac Client has been configured with the docker container."
           echo
           echo "Please login to the container using (root password mapr): ssh root@localhost -p 2222 "
           echo "Login to MCS at https://localhost:8443 "
         else
          echo
          echo "services didnt come up in stipulated 10 mins time"
          echo "please login to the container using ssh root@localhost -p 2222 with mapr as password and check further"
          echo "For documentation on steps to debug, see  https://docs.ezmeral.hpe.com/datafabric-customer-managed/home/MapRContainerDevelopers/TroubleshootMapRContainerDevelopers.html"
          echo
       fi
fi

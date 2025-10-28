# datafabric-customer-managed-sandbox

Introduction

The development environment script, mapr_devsandbox_container_setup.sh, downloads the Docker image associated with the container and launches the container image that starts the HPE Ezmeral Data Fabric cluster

#Steps

Use the following steps to bring up the container image and launch the Create Fabric interface:

1.Sign in to the sandbox host as root or a user that can run sudo commands without being prompted for a password.

2.Download the mapr_devsandbox_container_setup.sh script from GitHub. For example, download the script in its raw form by using the following wget command:

  wget https://raw.githubusercontent.com/mapr-demos/datafabric-customer-managed-sandbox/main/mapr_devsandbox_container_setup.sh

3.Modify the script so it is executable:

  chmod +x mapr_devsandbox_container_setup.sh 
 
4.Running the mapr_devsandbox_container_setup.sh script requires sudo privileges.

5.On the hose node make sure that docker is installed , started , up and running.

5.Run the script to deploy the container for the Data Fabric image:

  ./mapr_devsandbox_container_setup.sh 

6.The script brings up the latest Data Fabric version in containerized form. Console messages provide a link to a simple user interface that you can use to login to UI.

Documentation Link
For user documentation, see https://docs.ezmeral.hpe.com/datafabric-customer-managed/home/MapRContainerDevelopers/MapRContainerDevelopersOverview.html

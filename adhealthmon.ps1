This method was tried using a RHEL 8 server with MySQL as a Zabbix Server running inside an AWS EC2 Instance.
Prerequisite
RHEL 8
We will be using the default RHEL 8 AMI. Use an instance with minimal RAM of 2GB.

MySQL Server Version 8.0
To install mysql-server from yum repository, run this command below :
# yum install mysql-server
Installation
Install Zabbix Repository
# rpm -Uvh https://repo.zabbix.com/zabbix/4.2/rhel/8/x86_64/zabbix-release-4.2-2.el8.noarch.rpm
# dnf clean all
Install Zabbix server, frontend, and agent
# dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent
Create initial database
# mysql -u root -p 

mysql > CREATE DATABASE zabbix character set utf8 collate utf8_bin;
mysql > CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'password';
mysql > GRANT ALL PRIVILEGES ON zabbix. * TO 'zabbix'@'localhost';
mysql > quit;
Import initial schema and data.
# zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
Edit file /etc/zabbix/zabbix_server.conf and configure the Zabbix Server database
# vi /etc/zabbix/zabbix_server.conf

...
DBPassword=password
...
Edit file /etc/php-fpm.d/zabbix.conf, uncomment and set the right timezone.
# vi /etc/php-fpm.d/zabbix.conf

...
php_value[date.timezone] = Asia/Jakarta
...

Set Put SELinux in "Permissive" mode by editing the /etc/selinux/config and change the mode from enforcing to permissive (persists after reboots). SELinux by default will enforce prevention of Zabbix Server from starting.
# vi /etc/selinux/config

...
SELINUX=permissive
...
Start and enable the Zabbix Server, Frontend, and Agent Processes.
# systemctl restart zabbix-server zabbix-agent httpd php-fpm
# systemctl enable zabbix-server zabbix-agent httpd php-fpm

Frontend Configuration Wizard
Start configuration by connecting to the frontend : http://server_ip_or_name/zabbix

Make sure that all software prerequisites are met.


Enter details for connecting to the database.

Enter Zabbix server details.

Review a summary of settings.

Installation is completed. Configuration file is located in etc/zabbix/web/zabbix.conf.php

Login & Configuring User
Zabbix Frontend is ready. The default user name is Admin, password zabbix.


Once we are logged in, we will be redirected to the main dashboard.

To view information about users, go to Administration → Users.
Initially there are only two users defined in Zabbix :
'Admin' user is a Zabbix superuser, which has full permissions.
'Guest' user is a special default user. If you are not logged in, you are accessing Zabbix with “guest” permissions. By default, “guest” has no permissions on Zabbix objects.

To add a new user, click Create user.  In the new user form, make sure to add your user to one of the existing user groups, for example 'Zabbix administrators'.
Adding New Host
RHEL Zabbix Agent Installation

Connect to the intended agent server and run these commands below :
# rpm -Uvh https://repo.zabbix.com/zabbix/4.2/rhel/8/x86_64/zabbix-release-4.2-2.el8.noarch.rpm
# dnf clean all
# dnf -y install zabbix-agent
# systemctl start zabbix-agent 
Edit /etc/zabbix/zabbix_agentd.conf and add the server address.
# vi /etc/zabbix/zabbix_agentd.conf

...
Server=zabbix.server.neop
...
Windows Server Agent Installation

Connect to the intended agent server, download and run the Zabbix Agent Deployment Package.

Config Zabbix Server the agent server can contact, and complete the installation.


Creating New Host

Get back to the frontend dashboard, navigate to Configuration → Hosts, and click on Create host. This will present us with a host configuration form.

When done, click Add. Our new host should be visible in the hostlist.

Adding New Item
All items are grouped around hosts. That is why to configure a sample item we go to Configuration → Hosts and find the 'New host' we have created. The Items link in the row of 'Reverse Proxy 1' should display a count of '0'. Click on the link, and then click on Create item.

With an item defined, now we can check if it is actually gathering data. For that, go to Monitoring → Latest data, select 'Reverse Proxy 1' in the filter and click on Apply.

To view the graph, select the data and  click on the 'Graph' link next to the item.

Adding New Trigger
To configure a trigger for our item, go to Configuration → Hosts, find 'Reverse Proxy 1' and click on Triggers next to it and then on Create trigger.

With a trigger defined, if the RAM usage has exceeded the threshold level we defined in the trigger, the problem will be displayed in Monitoring → Problems.


Windows Zabbix Agent User Parameter
Create a new Powershell Script which later will be executed by Zabbix Agent and place it in C:\Program Files\Zabbix Agent\userparams_scripts\ (or any other directory depends on where will you define the directory inside the Zabbix Config File later). In this case, we will make a simple hostname reporter script called hostname.ps1.

$computername =$env:computername
Write-Output $computername

Open the Zabbix Agent config file (by default is located in C:\Program Files\Zabbix Agent\zabbix_agentd.conf), look for the UserParameter section, and add a user parameter.
...

### Option: UserParameter
#	User-defined parameter to monitor. There can be several user-defined parameters.
#	Format: UserParameter=<key>,<shell command>
#
# Mandatory: no
# Default:
UserParameter=simple.script, powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\userparams_scripts\hostname.ps1"

...

Go to Zabbix dashboard, navigate to Configuration → Hosts, and select a Windows Server Zabbix Agent. In this example, we will be using an Active Directory 1 server.

Select the host and create a new item. We will call our recently made user parameter simple.script.

Check the result by navigating to Monitoring → Latest Data and select the Active Directory 1 host. The given value will be shown under the Last Value column.

Email Notification
Go to the Zabbix Dashboard, navigate to Administration → Media Types, and click on Create media type.

Input media name, select type as Email, and input all the information required for the SMTP server that we will use.

Navigate to Administration → Users, and click on one of the users that we want to modify its media. In this case, we will be using Admin.

Go to Media tab, and add a media.

Select type Email and input address where the Email will be sent.

Navigate to Configuration → Actions, and click on Create action.

Inside the Action tab, input action name and add new condition. Select for the Trigger equals our recently made trigger.

Inside the Operations tab, input the default subject and message.

Add new Operations, and select the intended User/Group.

In Recovery Operations tab, input default subject, default message, and add Operations to Notify all involved.

In Update Operations tab, input default subject, default message, and add Operations to Notify all involved.



If the action is successfully triggered, there will be an email sent to the intended email address.

Slack API Notification
Slack App Preparation

Go to https://api.slack.com and click on Start Building button to build a new app.

Create a Slack App popup will appear. Input app name, select the development workspace, and then click Create App.

Select the Incoming Webhooks to add functionality of external source via post message which can be requested using a bash script.

Click on Activate Incoming Webhooks.

Scroll down and look for the Add New Webhook to Workspace button.

Select on where will we post our message be. In this case, we will post it in #general.

We will retrieve a sample curl POST request. The payload is in JSON format. For further details on messaging format in Slack, check here.

To test, copy the command to a Linux terminal.
$ curl -X POST -H 'Content-type: application/json' --data '{"text":"Hello, World!"}' https://hooks.slack.com/services/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


Bash Script Preparation

Inside the Zabbix Server, write a bash script inside Zabbix Alert directory. By default, it is located in /usr/lib/zabbix/alertscripts.

# vi  /usr/lib/zabbix/alertscripts slack.sh

#!/bin/bash

if [ "$2" == "Information"  ]
then
  color=#2F66A9
elif [ "$2" == "Warning" ]
then
  color=#F4C900
elif [ "$2" == "Average" ]
then
  color=#EF820D
elif [ "$2" == "High" ]
then
  color=#CC5500
elif [ "$2" == "Disaster" ]
then
  color=#CC0202
elif [ "$2" == "Resolved" ]
then
  color=#008F11
else
  color=#A19C9C
fi

json='{"attachments": [{ "color":"%s","pretext":"%s","title":"%s","text":"%s"}]}'

payload=$(printf "$json" "$color" "$1" "$2" "$3")

curl -X POST -H 'Content-type: application/json' --data "$payload"  https://hooks.slack.com/services/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

Zabbix Preparation

Go to the Zabbix Dashboard, navigate to Administration → Media Types, and click on Create media type.

Input media name, select type as script, input script name and script parameters.

Navigate to Administration → Users, and click on one of the users that we want to modify its media. In this case, we will be using Admin.

Go to Media tab, and add a media.

Select type Slack and input the Slack ID we would like to mention

If you’ve already done step 6-12 from the Email Notification part, then there will be a Slack message sent to the intended workspace.


Active Directory Health Monitoring
Powershell Script Preparation

Connect to a Windows Active Directory instance and create a new Powershell Script which later will be executed by Zabbix Agent and place it in C:\Program Files\Zabbix Agent\userparams_scripts\ and name it hostname.ps1.

#######################################################################################
# ADHealthMon.ps1                                                                     #
# Active Directory Health Monitoring Script for Windows Zabbix Agent                  #
# Coded by mamanberliansyah (https://github.com/mamanberliansyah)                     #
#                                                                                     #
# Based from Vikas Sukhija's AD Health Check Script                                   #
# https://gallery.technet.microsoft.com/scriptcenter/Active-Directory-Health-709336cd #
#######################################################################################

$timeout = "15"

function Test-Ping {
  Param($DC)
  if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) {
    Write-Output Success
  } else {
    Write-Output Failed
  }
}

function Test-Status {
  Param($DC,$stat)
  $serviceStatus = Start-Job -ScriptBlock {Get-Service -ComputerName $($args[0]) -Name $($args[1]) -ErrorAction SilentlyContinue} -ArgumentList $DC, $stat
  Wait-Job $serviceStatus -TimeOut $timeout  | Out-Null
  if($serviceStatus.state -like "Running") {
      Stop-Job $serviceStatus
      Write-Output TimeOut
  } else {
      $serviceStatus = Receive-Job $serviceStatus
      Write-Output $serviceStatus.status
  }
}

function Test-Sysvol {
  Param($DC,$vol)
  Add-Type -AssemblyName microsoft.visualbasic
  $cmp = "microsoft.visualbasic.strings" -as [type]
  $sysvol = Start-Job -ScriptBlock {dcdiag /test:$($args[0]) /s:$($args[1])} -ArgumentList $vol, $DC
  Wait-Job $sysvol -TimeOut $timeout  | Out-Null
  if($sysvol.state -like "Running") {
      Stop-Job $sysvol
      Write-Output TimeOut
  } else {
      $sysvol = Receive-Job $sysvol
      if($cmp::instr($sysvol, "passed test " + $vol)){
        Write-Output Passed
      } else {
        Write-Output Failed
      }
  }
}




Create a Slack App popup will appear. Input app name, select the development workspace, and then click Create App. 

# adhealthmon
Active Directory Domain Controller Health Monitoring using Powershell Script. It can be used on general monitoring cases. In my case, I integrated this script to run inside an Zabbix Agent Server.

## Usage :

Ping Test
```
PS C:\Users\Administrator> powershell -command "&{ . admon.ps1; Test-Ping -DC localhost}
```

NTDS Test
```
PS C:\Users\Administrator> powershell -command "&{ . admon.ps1; Test-Status -DC localhost -stat NTDS}
```

Replications Test
```
PS C:\Users\Administrator> powershell -command "&{ . admon.ps1; Test-Sysvol -DC localhost -vol Replications}
```

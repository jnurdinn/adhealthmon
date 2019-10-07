# adhealthmon
Active Directory Domain Controller Health Monitoring using Powershell Script

## Usage :

``Ping Test
PS C:\Users\Administrator> powershell -command "&{ . admon.ps1; Test-Ping -DC localhost}

NTDS Test
PS C:\Users\Administrator> powershell -command "&{ . admon.ps1; Test-Status -DC localhost -stat NTDS}

Replications Test
PS C:\Users\Administrator> powershell -command "&{ . admon.ps1; Test-Sysvol -DC localhost -vol Replications}``

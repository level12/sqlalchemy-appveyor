[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null

# Source: http://geekswithblogs.net/TedStatham/archive/2014/06/13/setting-the-ports-for-a-named-sql-server-instance-using.aspx
# Set the $instanceName value below to the name of the instance you
# want to configure a static port for. This could conceivably be
# passed into the script as a parameter.
$instanceName = 'SQL2008R2SP2'
$serverName = $env:COMPUTERNAME
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = New-Object ($smo + 'Wmi.ManagedComputer')

# Enable TCP/IP
$uri = "ManagedComputer[@Name='$serverName']/ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
$Tcp.IsEnabled = $true
$TCP.alter()

# Configure IPAll setting so SQL Server listens on 1433 on all IP address and doesn't use dynamic ports
$IPAllProps = $wmi.GetSmoObject($uri + "/IPAddress[@Name='IPAll']").IPAddressProperties
$IPAllProps["TcpDynamicPorts"].Value = ""
$IPAllProps["TcpPort"].Value = "1433"

# apply changes
$TCP.alter()

# Start services
Set-Service SQLBrowser -StartupType Manual
Start-Service "MSSQL`$$instanceName"

# wait a bit for the service to start to avoid login errors
Start-Sleep -s 10

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

# Configure IPAll setting so dynamic ports are not used
$IPAllProps = $wmi.GetSmoObject($uri + "/IPAddress[@Name='IPAll']").IPAddressProperties
$IPAllProps["TcpDynamicPorts"].Value = ""

# Only listen on the loopback addresses
$Tcp.ProtocolProperties["ListenOnAllIPs"].Value = $false
$loopback = $Tcp.IPAddresses | ? {$_.IPAddress -eq "127.0.0.1"}
$loopback.IPAddressProperties["TcpDynamicPorts"].Value = ""
$loopback.IPAddressProperties["TcpPort"].Value = "1433"
$loopback.IPAddressProperties["Enabled"].Value = $true

$loopbackv6 = $Tcp.IPAddresses | ? {$_.IPAddress -eq "127.0.0.1"}
$loopbackv6.IPAddressProperties["TcpDynamicPorts"].Value = ""
$loopbackv6.IPAddressProperties["TcpPort"].Value = "1433"
$loopbackv6.IPAddressProperties["Enabled"].Value = $true

# apply changes
$TCP.alter()

# Start services
Set-Service SQLBrowser -StartupType Manual
Start-Service "MSSQL`$$instanceName"

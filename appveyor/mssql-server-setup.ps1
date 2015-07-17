[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null


# Source: http://geekswithblogs.net/TedStatham/archive/2014/06/13/setting-the-ports-for-a-named-sql-server-instance-using.aspx
# Set the $instanceName value below to the name of the instance you
# want to configure a static port for. This could conceivably be
# passed into the script as a parameter.
$instanceName = 'SQL2008R2SP2'
$computerName = $env:COMPUTERNAME
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = New-Object ($smo + 'Wmi.ManagedComputer')

# For the named instance, on the current computer, for the TCP protocol,
# loop through all the IPs and configure them to use the standard port
# of 1433.
$uri = "ManagedComputer[@Name='$computerName']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
foreach ($ipAddress in $Tcp.IPAddresses)
{
    $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
    $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"
}
$Tcp.Alter()

# Start services
Set-Service SQLBrowser -StartupType Manual
Start-Service "MSSQL`$$instanceName"

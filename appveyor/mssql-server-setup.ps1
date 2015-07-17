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

# wait a bit for the service to start to avoid errors
Start-Sleep -s 3

#Create a new SqlConnection object
$objSQLConnection = New-Object System.Data.SqlClient.SqlConnection

Try
{
    $objSQLConnection.ConnectionString = "Server=$serverName;Integrated Security=SSPI;"
        Write-Host "Trying to connect to SQL Server instance on $serverName..." -NoNewline
        $objSQLConnection.Open() | Out-Null
        Write-Host "Success."
    $objSQLConnection.Close()
}
Catch
{
    Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
    $errText =  $Error[0].ToString()
        if ($errText.Contains("network-related"))
    {Write-Host "Connection Error. Check server name, port, firewall."}

    Write-Host $errText
    continue
}

#Create a new SMO instance for this $ServerName
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $serverName

#Find the SQL Server sa Login and Change the Password to something simple
$SQLUser = $srv.Logins | ? {$_.Name -eq "sa"};
Write-Host $env.SQL_PASS
$SQLUser.PasswordPolicyEnforced = 0;
$SQLUser.Alter();
$SQLUser.Refresh();
$SQLUser.ChangePassword($args[0]);
$SQLUser.Alter();
$SQLUser.Refresh();

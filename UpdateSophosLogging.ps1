Remove-Module Utilities
Import-Module .\Utilities.psm1
[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
[System.Reflection.Assembly]::LoadWithPartialName("System.Text.Encoding")
[System.Reflection.Assembly]::LoadWithPartialName("System.Security")
[System.Reflection.Assembly]::LoadWithPartialName("System.Collections")
#Setup API Connectivity
$config = Get-Content -Raw -Path .\config.json
$hashConfig = Get-ExpandedConfigFromJson -inputJson $config 

#Setup SQL Connection
$connect = $hashConfig.connectionString
$cn = new-object System.Data.SqlClient.SqlConnection($connect)

#Get List of Customers from DB
$sqlGetCustomers = "SELECT * FROM [SophosLogging].[dbo].[tblCustomers]"
Write-Output "Opening SQL Connection..."
$cn.Open()
$Command = $cn.CreateCommand()
$Command.CommandText = $sqlGetCustomers
$x = $result = $command.ExecuteReader()
$table = New-Object "System.Data.DataTable"
$table.Load($result)

ForEach ($row in $table.Rows){
    #Decode API Keys
    $customerId = $row.CustomerId
    $status = 0
    $statusMessage = "Success."
    $LastSync = Get-Date -Format G
    $apihash = $env:APIHASH
    
    $authorization = Decrypt-String -EncryptedText $row.ApiAuthorization -Password $apihash -Salt $row.ApiAuthorizationSalt
    $apikey = Decrypt-String -EncryptedText $row.ApiKey -Password $apihash -Salt $row.ApiKeySalt
    $hashConfig = Get-ExpandedConfigFromJson -inputJson $config -apikey $apikey -authorization $authorization

    #clear existing endpoints for customer
    $sqlDeleteCustomerEndpoints = "DELETE from [SophosLogging].[dbo].[tblEndpoints] WHERE CustomerId = @CustomerId"
    $Command = $cn.CreateCommand()
    $command.CommandText = $sqlDeleteCustomerEndpoints
    $x = $command.Parameters.AddWithValue("@CustomerId",$customerId)
    $x = $command.ExecuteNonQuery()

    #InvokeRequest - Endpoints
    $total = 1
    $count = 0
    while ($count -lt $total) {
        $url = $hashConfig.urls.EndpointUrl + "?" + "offset=$count"
        Try{
        $endpointResponse = Invoke-RestMethod -Method "GET" -Uri $url -Headers $hashConfig.headers
    }
    catch {
        $status = 1
        $statusMessage = "$statusMessage ; $_.Exception.Message"
    }
        $total = $endpointResponse.total
        $count += $endpointResponse.items.Count
        $sqlAddCustomerEndpoints = "INSERT INTO [dbo].[tblEndpoints]
        ([CustomerId]
        ,[Id]
        ,[Name]
        ,[AssignedProducts]
        ,[EndpointType]
        ,[LastUser]
        ,[LastActivity]
        ,[InfoPlatform]
        ,[InfoIsInDomain]
        ,[InfoDomainName]
        ,[InfoIpAddresses])
    VALUES
        (@CustomerId
        ,@Id
        ,@Name
        ,@AssignedProducts
        ,@EndpointType
        ,@LastUser
        ,@LastActivity
        ,@InfoPlatform
        ,@InfoIsInDomain
        ,@InfoDomainName
        ,@InfoIpAddress)"
        $command.CommandText = $sqlAddCustomerEndpoints
        foreach ($item in $endpointResponse.items) {
            $command.Parameters.Clear()
            $params = @{
                "@CustomerId" = $customerId
                "@Id" = $item.Id
                "@Name" = $item.Name
                "@AssignedProducts" = $item.assignedProducts -join ';'
                "@EndpointType" = $item.endpoint_type
                "@LastUser" = $item.last_user
                "@LastActivity" = $item.last_activity
                "@InfoPlatform" = $item.info.platform
                "@InfoIsInDomain" = $item.Info.isInDomain
                "@InfoDomainName" = $item.Info.domain_name
                "@InfoIpAddress"= $item.Info.'ipAddresses/ipv4' -join ';'
            }
            foreach ($p in $params.Keys){
               $x = $command.Parameters.AddWithValue($p,$params[$p])
            }
            $x = $command.ExecuteNonQuery()
        }
    }

    #Invoke Request - Alerts
        $url = $hashConfig.urls.AlertUrl
        try {
            $alertResponse = Invoke-RestMethod -Method "GET" -Uri $url -Headers $hashConfig.headers           
        }
        catch {
            $status = 1
            $statusMessage = "$statusMessage ; $_.Exception.Message"
        }

        $sqlAddCustomerAlerts = "IF not EXISTS( SELECT * From [dbo].[tblAlerts] Where Id = @Id)
        BEGIN
        INSERT INTO [dbo].[tblAlerts]
        ([CustomerId]
        ,[Id]
        ,[Location]
        ,[Severity]
        ,[AlertDate]
        ,[DataEndpointId]
        ,[DataEndpointPlatform]
        ,[AlertType]
        ,[AlertSource]
        ,[AlertDescription])
    VALUES
    (@CustomerId
    ,@id
    ,@location
    ,@severity
    ,@alertdate
    ,@dataendpointid
    ,@dataendpointplatform
    ,@alerttype
    ,@alertsource
    ,@alertdescription)
    END"
        $command.CommandText = $sqlAddCustomerAlerts
        foreach ($item in $alertResponse.items) {
            $command.Parameters.Clear()
            $params = @{
                "@CustomerId" = $customerId
                "@Id" = $item.Id
                "@location" = $item.location
                "@severity" = $item.severity
                "@alertdate" = $item.when
                "@dataendpointid" = $item.data.endpoint_id
                "@dataendpointplatform" = $item.data.endpoint_platform
                "@alerttype" = $item.type
                "@alertsource" = $item.source
                "@alertdescription" = $item.description
            }
            foreach ($p in $params.Keys){
               $x = $command.Parameters.AddWithValue($p,$params[$p])
            }
            $x = $command.ExecuteNonQuery()
        }

        #Invoke Request - Events
        $url = $hashConfig.urls.EventUrl
        Try{
        $eventResponse = Invoke-RestMethod -Method "GET" -Uri $url -Headers $hashConfig.headers
    }
    catch {
        $status = 1
        $statusMessage = "$statusMessage ; $_.Exception.Message"
    }
        $sqlAddCustomerEvents = "IF not EXISTS(SELECT * From [dbo].[tblEvents] Where Id = @id)
        BEGIN
        INSERT INTO [dbo].[tblEvents]
        ([CustomerId]
        ,[Id]
        ,[Location]
        ,[Severity]
        ,[EventDate]
        ,[EventSource]
        ,[EventType]
        ,[EventName]
        ,[EventGroup])
  VALUES
        (@CustomerId
        ,@id
        ,@location
        ,@severity
        ,@EventDate
        ,@EventSource
        ,@EventType
        ,@EventName
        ,@EventGroup)
        END"
        $command.CommandText = $sqlAddCustomerEvents
        foreach ($item in $eventResponse.items) {
            $command.Parameters.Clear()
            $params = @{
                "@CustomerId" = $customerId
                "@Id" = $item.Id
                "@location" = $item.location
                "@severity" = $item.severity
                "@EventDate" = $item.when
                "@EventSource" = $item.source
                "@EventType" = $item.type
                "@EventName" = $item.name
                "@EventGroup" = $item.group
            }
            foreach ($p in $params.Keys){
               $x = $command.Parameters.AddWithValue($p,$params[$p])
            }
            $x = $command.ExecuteNonQuery()
        }
        #Update LastSync for client
        $command = $cn.CreateCommand()
        $sqlClose = "UPDATE [dbo].[tblCustomers]
        SET 
           [LastSync] = @LastSync
           ,[Status] = @Status
           ,[StatusMessage] = @StatusMessage
        WHERE CustomerId = @CustomerId"
        $command.CommandText = $sqlClose
        $params = @{
            "@CustomerId" = $customerId
            "@LastSync" = "$($LastSync)"
            "@Status" = $status
            "@StatusMessage" = $statusMessage
        }
        foreach ($p in $params.Keys) {
            $x  = $command.Parameters.AddWithValue($p,$params[$p])
        }
        $x = $command.ExecuteNonQuery()
        #Pause before moving to next client
        Start-Sleep -Seconds 30
    }
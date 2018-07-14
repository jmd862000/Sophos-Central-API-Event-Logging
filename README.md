# Sophos-Central-API-Event-Logging
Retrieves Computers, Events, and Alerts for designated customers from the Sophos Central API and stores them in a SQL Database.

* Encode the API Key and Authorization using the Get-EncryptedApiKeys. The secret must be stored in the $env:APIHASH variable.
  * Store the resulting values in the customer record in the Customers table

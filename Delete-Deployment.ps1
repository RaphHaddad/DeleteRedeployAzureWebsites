param (
    [string]$AzureServiceName = $(throw "-AzureServiceName is required"),
    [ValidateSet("Production","Staging")][string]$AzureSlot = $(throw "-AzureSlot is required"),
    [string]$AzureCertificateThumbprint = $(throw "-AzureCertificateThumbprint is required"),
	[string]$AzureSubscriptionId = $(throw "-AzureSubscriptionId is required")
)

Set-AzureSubscription -SubscriptionId $AzureSubscriptionId -Certificate (Get-Item "Cert:\CurrentUser\my\$AzureCertificateThumbprint")

function DeleteDeployment($azureServiceName, $azureSlot)
{
    $deployment = Get-AzureDeployment -ServiceName $azureServiceName -Slot $azureSlot -ErrorVariable a -ErrorAction silentlycontinue

    if (($a[0] -ne $null) -or ($deployment.Name -eq $null)) 
    {
        Write-Host "No Deployment to delete..."
    }
    else
    {
        Write-Host "Deleting deployment..."
        Remove-AzureDeployment -ServiceName $azureServiceName -Slot $azureSlot -Force
    }
}

DeleteDeployment -azureServiceName $AzureServiceName -azureSlot $AzureSlot
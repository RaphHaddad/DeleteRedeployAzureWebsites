param (
    [string]$OctopusEnvironment = $(throw "-OctopusEnvironment is required"),
    [string]$OctopusProjectName = $(throw "-OctopusProjectName is required"),
    [string]$OctopusServerUrl = $(throw "-OctopusServerUrl is required"),
    [string]$OctopusApiKey = $(throw "-OctopusApiKey is required")
)


Write-Host "OctopusEnvironment: $OctopusEnvironment"
Write-Host "OctopusProjectName: $OctopusProjectName"
Write-Host "OctopusServerUrl: $OctopusServerUrl"
Write-Host "OctopusApiKey: $OctopusApiKey"

function Get-OctopusEnvironment($environmentName)
{
    $environments = Invoke-RestMethod -Uri "$OctopusServerUrl/api/environments/all" -Headers $headers
    ($environments | where{$_.Name -eq $environmentName})
}

function Get-OctopusProject($projectName)
{
    $projects = Invoke-RestMethod -Uri "$OctopusServerUrl/api/projects/all" -Headers $headers
    ($projects | where{$_.Name -eq $projectName})
}

function Get-OctopusDeployments($environmentId,$projectId)
{
	$triesElapsed = 0
	$maximumRetries = 60
	$waitInterval = [System.TimeSpan]::FromSeconds(30)
    do
    {
		$triesElapsed+=1
		[System.Threading.Thread]::Sleep($waitInterval)
        Write-Host "Checking Octopus API, current try is $triesElapsed/$maximumRetries"

        $deployments = Invoke-RestMethod -Uri "$OctopusServerUrl/api/deployments?environments=$environmentId&projects=$projectId" -Headers $headers 
        if ($deployments.IsStale)
        {
            Write-Host "The Octopus API is stale. We will try again"
        }
        else 
        {
            return $deployments.Items
        }

		if($triesElapsed -ge $maximumRetries)
		{
			throw "Octopus API is consistently stale after 30 minutes. Something is wrong."
		}

    }While($triesElapsed -le $maximumRetries)
}

function Create-OctopusDeployment($environmentId,$releaseId,$project)
{
    $objToSend = @{"EnvironmentId"=$environmentId; "ReleaseId"=$releaseId}
    $jsonToSend = (ConvertTo-Json $objToSend)
    Invoke-RestMethod -Method Post -Uri "$OctopusServerUrl/api/deployments" -Body $jsonToSend -Headers $headers
}

function Get-OctopusRelease($deployment)
{
    $releaseUri = $latestDeployment.Links.Release
    Invoke-RestMethod -Uri "$OctopusServerUrl/$releaseUri" -Headers $headers
}

$headers = @{"X-Octopus-ApiKey"=$OctopusApiKey}

$env = Get-OctopusEnvironment $OctopusEnvironment 

$proj = Get-OctopusProject $OctopusProjectName

$latestDeployment = Get-OctopusDeployments -environmentId $env.Id -projectId $proj.Id | select -First 1 

$release =  Get-OctopusRelease $latestDeployment

Create-OctopusDeployment -environmentId $env.Id -releaseId $release.Id  -project $proj
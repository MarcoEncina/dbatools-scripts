﻿# Requires -Version 4
# Requires module dbatools
## This is getting a list of server name from Hyper-V - You can chagne this to a list of SQL instances
$SQLServers = (Get-VM -ComputerName $Config.IdentityColumn.HyperV -ErrorAction SilentlyContinue| Where-Object {$_.Name -like "*$($Config.IdentityColumn.NameSearch)*" -and $_.State -eq 'Running'}).Name
if(!$SQLServers){Write-Warning "No Servers to Look at - Check the config.json"}
foreach($SQLServer in $SQLServers)
{
    Describe "$SQLServer - Testing how full the Identity columns are" -Tag Column, Detailed, Identity{
            $dbs = (Connect-DbaSqlServer -SqlServer $SQLServer).Databases.Name
            foreach($db in $dbs)
            {
                Context "Testing $db" {
                $Tests = Test-DbaIdentityUsage -SqlInstance $SQLServer -Databases $db -WarningAction SilentlyContinue
                foreach($test in $tests)
                {
                    It "$($test.Column) identity column in $($Test.Table) is less than $($Config.IdentityColumn.Percent) % full" -Skip:$($Config.IdentityColumn.Skip){
                        $Test.PercentUsed | Should BeLessThan $($Config.IdentityColumn.Percent)
                    }
                }
            }
        }
    }
}
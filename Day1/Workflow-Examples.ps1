##############################################################################
# The following demos PowerShell 3.0+ workflows.
# For more information, run 'Get-Help about_Workflows'.
# A workflow is a set of actitivies that can run in sequence or parallel, can
# be stopped and restarted, can run as background jobs, survive reboots, and
# can be embedded in a parent workflow along with other child workflows.  
# The state of a workflow can be persisted for later resumption.
##############################################################################




Workflow VariablesAtWorkflowScope1
{
    # This variable is at workflow scope:
    $inbound = 1

    Parallel
    {
        # The $inbound variable can be read without a scope modifier:
        $inbound

        # But to modify $inbound, the "$workflow:" modifier must be used:
        $workflow:inbound = 2
        $inbound
    }
}


VariablesAtWorkflowScope1




##############################################################################



Workflow VariablesAtWorkflowScope2
{
    # This variable is at workflow scope and can be used to collect
    # the output of multiple parallel commands:
    $output = @() 

    Parallel
    {
        # Placing the commands within "@(...)" reduces error messages,
        # but it is often not necessary, it depends on the commands.
        # And notice the "+=" assignments to cope with parallel flows.
        $workflow:output += @( dir c:\ ) 
        $workflow:output += @( ps lsa* | select name ) 
        $workflow:output += @( get-alias ps ) 
    }

    $output 
} 


VariablesAtWorkflowScope2




##############################################################################



Workflow VariablesAtWorkflowScope3
{
    # This variable is at workflow scope and can be used to collect
    # the output of multiple parallel commands:
    $output = @() 
    
    Parallel
    {
        # To run commands in a new PowerShell process, place them in an InLineScript
        # block, then capture their output to a variable at some scope:
        $workflow:output += InLineScript { dir c:\ } 
        
        # This variable is local to the parallel block and cannot be identical in
        # name to another variable at workflow scope:
        $para = InLineScript { ps svc* | select name } 
        
        # This line does not add to the output of the workflow, it is local to this block:
        $para

        # InLineScript blocks may contain commands and syntax forbidden in workflows:
        $workflow:output += InlineScript { get-alias ps } 
    }

    # This line adds to the output of the workflow, but the variable only contains $null:
    '$para contains nothing? : ' + ($para -eq $null)  

    # This variable contains data and will be returned by the workflow:
    $output | select name
}


VariablesAtWorkflowScope3




##############################################################################


# The following demos the use of 'ForEach -Parallel'.



#.Parameter Filter
#   Query string to Get-ADComputer, defaults to *.
#.Parameter SearchBase
#   Distinguished name path to a domain or OU with computers to ping.

Workflow Parallel-Ping
{
    Param ( $Filter = "*", $SearchBase = "" )

    # If -SearchBase is $null, then default to searching entire local domain; note
    # that Workflows can only take simple parameter types, like Int32 and String,
    # which explains why the following lines are used instead of editing Param:
    if ($SearchBase.Length -eq 0)
    { $SearchBase = (Get-ADDomain -Current LocalComputer).DistinguishedName } 


    # Create a hashtable of the fully-qualified names for every computer in the domain
    # and set the value for each item to $True to assume that it can be pinged, the
    # idea being that most computers should be on-line and pingable in a domain:
    $DnsHostNames = @{}
    Get-ADComputer -Filter $Filter -SearchScope Subtree -SearchBase $SearchBase -Properties DNSHostName | 
    ForEach { if ($_.DNSHostName.Length -ne 0) { $DnsHostNames.Add( $_.DNSHostName, $True ) } } 
    

    # Now ping every FQDN in parallel, recording the names of hosts that cannot be pinged;
    # notice the -Parallel switch to the ForEach keyword:
    $FailureNames = ForEach -Parallel ( $HostName in $DnsHostNames.Keys ) 
    {
        if (-not (Test-Connection -ComputerName $HostName -Count 2 -Quiet -ErrorAction SilentlyContinue ))
        { $HostName } 
    }


    # Update hashtable with the list of hosts that cannot be pinged:
    if ($FailureNames.Count -gt 0)
    { $FailureNames | ForEach { $DnsHostNames."$_" = $False } }  


    # Return the completed hashtable, where $True = IsPingable:
    $DnsHostNames
}


# Run the workflow, similar to calling a function:
#  Parallel-Ping -Filter "CN -like '*a*'" 




##############################################################################




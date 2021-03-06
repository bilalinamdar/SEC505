# To debug a PowerShell script, you must set at least one breakpoint.
# There are three types of breakpoints: line, variable, and command.
# Only line breakpoints can be created by the ISE's menu options, but
# all breakpoint types can be created from the command line.  Note
# that breakpoints are memory-resident only, they do not survive the
# restart of the PowerShell host process which created them.  


###################################################################
#
# List, disable, enable and remove breakpoints:
#
###################################################################

# List all breakpoints and their ID numbers: 
Get-PSBreakpoint

# Disable a breakpoint by its ID number:
Disable-PSBreakpoint -Id 0

# Disable all breakpoints:
Get-PSBreakpoint | Enable-PSBreakpoint

# Enable a breakpoint by its ID number:
Enable-PSBreakpoint -Id 0

# Enable all breakpoints:
Get-PSBreakpoint | Enable-PSBreakpoint

# Remove a breakpoint by its ID number:
Remove-PSBreakpoint -Id 0

# Remove all breakpoints:
Get-PSBreakpoint | Remove-PSBreakpoint



###################################################################
#
# Set basic breakpoints by line, variable or command name:
#
###################################################################

# Set a breakpoint on a line number:
Set-PSBreakpoint -Line 128 -Script .\Debugging-Notes.ps1

# Set a breakpoint when a variable is modified, such as $x:
Set-PSBreakpoint -Variable x -Script .\Debugging-Notes.ps1

# Set a breakpoint on any invocation of command, such as Get-Date:
Set-PSBreakpoint -Command 'Get-Date' -Script .\Debugging-Notes.ps1



###################################################################
#
# Set more complex breakpoints:
#
###################################################################

# Set a breakpoint on READ access of a variable, such as $i:
Set-PSBreakpoint -Variable i -Mode Read -Script .\Debugging-Notes.ps1

# Set a breakpoint on WRITE access of a variable (this the default):
Set-PSBreakpoint -Variable i -Mode Write -Script .\Debugging-Notes.ps1

# Set a breakpoint on READ or WRITE access of a variable, such as $i:
Set-PSBreakpoint -Variable i -Mode ReadWrite -Script .\Debugging-Notes.ps1

# Ignore a breakpoint unless a test (the -Action block) runs 'break':
Set-PSBreakpoint -Variable x -Script .\Debugging-Notes.ps1 -Action { if ($x -ge 3){ break } }  
Set-PSBreakpoint -Command 'Get-Service' -Script .\Debugging-Notes.ps1 -Action { if ($host.Version.Major -lt 4){ break } } 
Set-PSBreakpoint -Command 'dir' -Action { if ($pwd.path -like '*Temp*'){ break } } 

# Set a breakpoint on any command that matches a string with a wildcard:
Set-PSBreakpoint -Command 'Stop-*' -Script .\Debugging-Notes.ps1



###################################################################
#
# Set breakpoints for the current session too, not just scripts:
#
###################################################################

Set-PSBreakpoint -Command 'ps'
Set-PSBreakpoint -Variable myvar 



<# ################################################################ 

Once the script runs and a breakpoint is hit, use the following
commands to investigate the state of the script in debugging mode
at the command line in either ISE or the text-only console host:

  h       Display help ("?" also displays help).
  c       Continue running until the next breakpoint or the end.
  k       Show call stack, most recent at the top.
  q       Quit debugging.
  s       Run line and follow calls into function bodies.
  v       Run line, but do not follow calls into function bodies.
  o       Run like "v", then move up one layer of nested functions.
  l       List source code lines, with asterisk next to current line.
  l x y   List source code lines between lines x and y.
  d       Detach from job or runspace (see Debug-Job and Debug-Runspace).
  Enter   Repeat last command (only for "s", "v" or "l").

To show variable contents, run that variable ($x) or hover your
pointer over that variable in the script pane of the ISE editor.
This does not work for "$_", "$Input", "$Args" and a few other
special variables; assign those to temp variables to examine.

The contents of variables may also be changed in debug mode.

Other commands may be run in debug mode too, such as Get-Process.

When an error occurs, show all details using the -Force switch:

   $error[0] | format-list * -force

The following lines are for playing with debug mode.  Run this
script like normal, then press "h" to show help again.  In ISE,
watch the yellow highlighting in the script pane as you step.

################################################################ #>




$i = 0
$x = 33
[String[]] $d = @() 

function show-millistring ($m) { [String]$m + " milliseconds `n" }  

function get-milly { show-millistring -m (Get-Date).Millisecond } 

1..5 | ForEach { $d += get-milly } 

$d 

Get-PSBreakpoint | Remove-PSBreakpoint #Remove all breakpoints.


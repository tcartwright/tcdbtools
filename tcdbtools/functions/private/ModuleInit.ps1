<#
    Original credits: https://newbedev.com/powershell-assembly-binding-redirect-not-found-in-application-configuration-file

    Purpose: To provide an assembly resolve event that does not crash PowerShell with a stackoverflow exception, and works.
    A pure powershell assembly resolver often times will crash.

    Tim Cartwright:
        This resolver only works with assemblies that are already in your cache but the assembly asked for has a different version.
        Rewrote to be less complicated, and to resolve 100% of the time IF the assembly has already been loaded with a diff version.
        If need be, before the resolver is called, either use Add-Type, or [System.Reflection.Assembly]::LoadWithPartialName("")
        to load the assembly needed before hand if it is not already in your cache.


    TO VERIFY IF THE NEEDED ASSEMBLY IS IN YOUR CACHE:

    [System.AppDomain]::CurrentDomain.GetAssemblies() | Sort-Object { $_.Location } | Out-GridView # USE FILTER AT THE TOP OF WINDOW
#>
if (!("TCAssemblyRedirector" -as [type])) {
    $source = @'
        using System;
        using System.Linq;
        using System.Reflection;

        public class TCAssemblyRedirector
        {
            public TCAssemblyRedirector()
            {
                this.AssemblyResolver += new ResolveEventHandler(AssemblyResolve);
            }

            public ResolveEventHandler AssemblyResolver;

            protected Assembly AssemblyResolve(object sender, ResolveEventArgs resolveEventArgs)
            {
                // Console.WriteLine("Resolver called with {0}", resolveEventArgs.Name);
                var name = resolveEventArgs.Name.Split(',').FirstOrDefault();
                var assembly = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(a => string.Compare(a.GetName().Name, name, true) == 0);

                //if (assembly != null)
                //{
                //    Console.WriteLine("Redirecting {0} to {1}", resolveEventArgs.Name, assembly.GetName().FullName);
                //}
                return assembly;
            }
        }
'@

    Add-Type -TypeDefinition $source -PassThru | Out-Null
}

$redirector = [TCAssemblyRedirector]::new()
[System.AppDomain]::CurrentDomain.add_AssemblyResolve($redirector.AssemblyResolver)


$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$binPath = [System.IO.Path]::Combine($scriptDir, "..\..\bin")
$script:tcdbtools_SqlDir = [System.IO.Path]::Combine($scriptDir, "..\..\sql")

# load up SMO by default for all scripts.... hopefully. MSFT recently changed SMO to a nuget package which really jacks with finding it, or downloading it automatically
[System.Reflection.Assembly]::LoadFrom("$binPath\smo\Microsoft.SqlServer.Smo.dll") | Out-Null
[System.Reflection.Assembly]::LoadFrom("$binPath\smo\Microsoft.SqlServer.ConnectionInfo.dll") | Out-Null





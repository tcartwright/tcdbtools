
$code = @"
using System;
using System.Management.Automation;

namespace TCDbTools {
    public class DBServer {
        public string ServerInstance { get; set; }
        public string Database { get; set; }
        public PSCredential Credentials { get; set; }

        public DBServer(string serverInstance, string database = "master", PSCredential credentials = null) {
            this.ServerInstance = serverInstance;
            this.Database = database;
            this.Credentials = credentials;
        }
    }
}
"@
Add-Type -TypeDefinition $code -Language CSharp

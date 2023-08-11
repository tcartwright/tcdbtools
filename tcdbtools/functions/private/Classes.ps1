
$code = @"
using System;
using System.Management.Automation;
using System.Collections;

namespace TCDbTools {
	public class DBServer {
		public string ServerInstance { get; set; }
		public string Database { get; set; }
		public PSCredential Credentials { get; set; }
        public Hashtable SqlCmdArgs { get;set;}

        public DBServer(string serverInstance, string database = "master", PSCredential credentials = null, Hashtable sqlCmdArgs = null) {
			this.ServerInstance = serverInstance;
			this.Database = database;
			this.Credentials = credentials;
			this.SqlCmdArgs = sqlCmdArgs;
		}
	}
}
"@
Add-Type -TypeDefinition $code -Language CSharp


if (!("TCDbTools.DBServer" -as [type])) {
    $code = @"
    using System;
    using System.Management.Automation;
    using System.Collections;
    
    namespace TCDbTools
    {
        /// <summary>
        /// Class that is used by various functions to connect to multiple servers and databases.
        /// </summary>
        public class DBServer
        {
            /// <summary>
            /// Gets or sets the server instance.
            /// </summary>
            /// <value>
            /// The server instance.
            /// </value>
            public string ServerInstance { get; set; }
            /// <summary>
            /// Gets or sets the database.
            /// </summary>
            /// <value>
            /// The database.
            /// </value>
            public string Database { get; set; }
            /// <summary>
            /// Gets or sets the credentials.
            /// </summary>
            /// <value>
            /// The credentials.
            /// </value>
            public PSCredential Credentials { get; set; }
            /// <summary>
            /// Gets or sets the SQL command arguments.
            /// </summary>
            /// <value>
            /// The SQL command arguments.
            /// </value>
            public Hashtable SqlCmdArgs { get;set;}
    
            /// <summary>
            /// Initializes a new instance of the <see cref="DBServer"/> class.
            /// </summary>
            /// <param name="serverInstance">The server instance.</param>
            /// <param name="database">The database.</param>
            /// <param name="credentials">The credentials.</param>
            /// <param name="sqlCmdArgs">The SQL command arguments. Used for command Invoke-DBScriptRunner</param>
            public DBServer(string serverInstance, string database = "master", PSCredential credentials = null, Hashtable sqlCmdArgs = null)
            {
                this.ServerInstance = serverInstance;
                this.Database = database;
                this.Credentials = credentials;
                this.SqlCmdArgs = sqlCmdArgs;
            }
        }
    }
"@
    Add-Type -TypeDefinition $code -Language CSharp | Out-Null
}
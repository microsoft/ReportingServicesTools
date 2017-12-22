$source = @"
using System.Management.Automation;

namespace Microsoft.ReportingServicesTools
{
    /// <summary>
    /// Static class containing connection information to the reporting server.
    /// </summary>
    public static class ConnectionHost
    {
        /// <summary>
        /// The name of the computer to connect to using WMI
        /// </summary>
        public static string ComputerName = "localhost";

        /// <summary>
        /// The name of the Database instance of the Report Server
        /// </summary>
        public static string Instance = "MSSQLSERVER";

        /// <summary>
        /// The version of the Report Server
        /// </summary>
        public static SqlServerVersion Version = SqlServerVersion.SQLServer2016;

        /// <summary>
        /// The credentials to use when connecting to the reporting services.
        /// </summary>
        public static PSCredential Credential;

        /// <summary>
        /// The uri through which to connect to the Report Server SOAP endpoint
        /// </summary>
        public static string ReportServerUri = @"http://localhost/reportserver/";

        /// <summary>
        /// The uri through which to connect to the Report Portal OData endpoint
        /// </summary>
        public static string ReportPortalUri = @"http://localhost/reports/";

        /// <summary>
        /// Stores an existing WebProxy object, to avoid having to process a new object each and every time
        /// </summary>
        public static object Proxy;
    }

    /// <summary>
    /// The various authentication schemes an smtp server used by the reporting services may use
    /// </summary>
    public enum SmtpAuthentication
    {
        /// <summary>
        /// Connect to a mail server without any authentication.
        /// </summary>
        None = 0,

        /// <summary>
        /// Connect to a mail server with basic authentication.
        /// </summary>
        Basic = 1,

        /// <summary>
        /// Connect to a mail server using NTLM authentication.
        /// </summary>
        Ntlm = 2
    }

    /// <summary>
    /// What authentication type to use when connecting with an SQL Server
    /// </summary>
    public enum SqlServerAuthenticationType
    {
        /// <summary>
        /// Default Windows Authentication
        /// </summary>
        Windows = 0,

        /// <summary>
        /// The SQL Server handles identity and authorization itself
        /// </summary>
        SQL = 1,

        /// <summary>
        /// Connect to SQL Server using the same account as the one which Reporting Services Service is running as.
        /// </summary>
        ServiceAccount = 2
    }

    /// <summary>
    /// The various versions of SQL Server
    /// </summary>
    public enum SqlServerVersion
    {
        /// <summary>
        /// SQL Server 2012
        /// </summary>
        SQLServer2012 = 11,

        /// <summary>
        /// SQL Server 2014
        /// </summary>
        SQLServer2014 = 12,

        /// <summary>
        /// SQL Server 2016
        /// </summary>
        SQLServer2016 = 13,

        /// <summary>
        /// SQL Server 2017
        /// </summary>
        SQLServer2017 = 14,

        /// <summary>
        /// SQL Server vNext
        /// </summary>
        SQLServervNext = 15
    }
}
"@

Try { Add-Type -TypeDefinition $source -ErrorAction Stop }
catch { }

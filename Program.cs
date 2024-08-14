using System;
using System.Data.Odbc;

class Program
{
    static void Main(string[] args)
    {
        CreateOdbcConnection();
    }

    static private void CreateOdbcConnection()
    {
        // Use OdbcConnectionStringBuilder to construct the connection string
        OdbcConnectionStringBuilder builder = new OdbcConnectionStringBuilder();

        // Set the properties for the connection string
        builder.Driver = "Simba Spark ODBC Driver";
        builder.Add("Host", "<your_adb_host>");
        builder.Add("Port", "443");
        builder.Add("HTTPPath", "sql/protocolv1/o/3775820491380537/0801-184302-vhql1pfz");
        builder.Add("AuthMech", "3");
        builder.Add("UID", "token");
        builder.Add("PWD", "<your_adb_token>");
        builder.Add("SSL", "1");
        builder.Add("ThriftTransport", "2");

        // Get the constructed connection string
        string connectionString = builder.ConnectionString;

        using (OdbcConnection connection = new OdbcConnection(connectionString))
        {
            try
            {
                // Open the connection
                connection.Open();
                Console.WriteLine("Connection opened successfully.");

                // Example query
                string query = "SELECT * FROM gold.gold_roads LIMIT 10";

                using (OdbcCommand command = new OdbcCommand(query, connection))
                {
                    using (OdbcDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            // Loop through each column in the row and print its value
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                Console.Write($"{reader.GetName(i)}: {reader[i]} ");
                            }
                            Console.WriteLine(); // New line after each row
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred: {ex.Message}");
            }
        }
    }
}

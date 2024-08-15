using System;
using System.Data.Odbc;
using System.IO;
using Newtonsoft.Json.Linq;

class Program
{
    static void Main(string[] args)
    {
        CreateOdbcConnection();
    }

    static private void CreateOdbcConnection()
    {
        // Read the connection settings from the JSON file
        var connectionSettings = JObject.Parse(File.ReadAllText("connectionSettings.json"));

        // Use OdbcConnectionStringBuilder to construct the connection string
        OdbcConnectionStringBuilder builder = new OdbcConnectionStringBuilder();

        // Set the properties for the connection string from the JSON file
        builder.Driver = connectionSettings["Driver"].ToString();
        builder.Add("Host", connectionSettings["Host"].ToString());
        builder.Add("Port", connectionSettings["Port"].ToString());
        builder.Add("HTTPPath", connectionSettings["HTTPPath"].ToString());
        builder.Add("AuthMech", connectionSettings["AuthMech"].ToString());
        builder.Add("UID", connectionSettings["UID"].ToString());
        builder.Add("PWD", connectionSettings["PWD"].ToString());
        builder.Add("SSL", connectionSettings["SSL"].ToString());
        builder.Add("ThriftTransport", connectionSettings["ThriftTransport"].ToString());

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
                string query = "SELECT * FROM dev_catalog.bronze.raw_roads LIMIT 10";

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

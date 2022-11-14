using Amazon.Lambda.Core;

using Amazon.S3;
using Amazon.S3.Model;
using Common.Models;

using ClosedXML.Excel;

using static SnsSendMessage;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace parse_csv;

public class Function
{
    IAmazonS3 S3Client { get; set; }

    /// <summary>
    /// Default constructor. This constructor is used by Lambda to construct the instance. When invoked in a Lambda environment
    /// the AWS credentials will come from the IAM role associated with the function and the AWS region will be set to the
    /// region the Lambda function is executed in.
    /// </summary>
    public Function()
    {
        S3Client = new AmazonS3Client();
    }

    /// <summary>
    /// Constructs an instance with a preconfigured S3 client. This can be used for testing the outside of the Lambda environment.
    /// </summary>
    /// <param name="s3Client"></param>
    public Function(IAmazonS3 s3Client)
    {
        this.S3Client = s3Client;
    }

    /// <summary>
    /// A function that reads from an S3 object (via S3Put Event trigger) and outputs that data
    /// </summary>
    /// <param name="input"></param>
    /// <param name="context"></param>
    /// <returns></returns>
    public async Task<string> FunctionHandler(Payload input, ILambdaContext context)
    {
        // NOTE: files with space in the name do not work!
        var returnString = "";
        foreach (Record record in input.Records) {
            Console.WriteLine(record.s3.@object.key);
            var request = new GetObjectRequest()
            {
                BucketName = record.s3.bucket.name,
                Key = record.s3.@object.key
            };

            using (var res = S3Client.GetObjectAsync(request))
            {
                if (record.s3.@object.key.EndsWith("csv")) {
                    // parse CSV file
                    Console.WriteLine("We've got a CSV file!");
                    StreamReader sReader = new StreamReader(res.Result.ResponseStream);

                    while (!sReader.EndOfStream) {
                        var line = sReader.ReadLine();
                        var values = line.Split(',');
                        foreach (var item in values){
                            Console.WriteLine("ITEM: " + item);
                        }
                        // foreach (var coloumn1 in listA){
                        //     Console.WriteLine(coloumn1);
                        // }
                        Console.WriteLine("ROW");
                    }
                } else {
                    // Parse Excel File
                    Console.WriteLine("We've got an Excel file!");

                    using (var workbook = new XLWorkbook(res.Result.ResponseStream))
                    {
                        var ws1 = workbook.Worksheet(1); 

                        var rows = ws1.RangeUsed().RowsUsed().Skip(1); // Skip header row
                        foreach (var row in rows)
                        {
                            var rowNumber = row.RowNumber();
                            var name = row.Cell(1).Value; // Name
                            DateTime birthDate = (DateTime) row.Cell(2).Value; // Birth Date
                            // Process the row
                            Console.WriteLine(birthDate.GetType());
                            string month = birthDate.ToString("MMMM").ToLower();
                            int day = birthDate.Day;
                            Console.WriteLine("Row number: " + rowNumber + " " + name + " " + birthDate);
                            Console.WriteLine("Month and Day: " + month + " " + day);
                        }
                    }
                }
            }
            returnString += $"Successfully read {record.s3.bucket.name}/{record.s3.@object.key}.";

            // TODO: do something with this parsed data via database
        }
        // TODO: Write to SNS send-notification-process-update topic
        var message = new SnsSendMessage();
        await message.Send("arn:aws:sns:us-east-1:828402573329:send-process-update-notification", "test message");
        return returnString;
    }
}

using Amazon.Lambda.Core;

using Amazon.S3;
using Amazon.S3.Model;
using Common.Models;

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
    public string FunctionHandler(Payload input, ILambdaContext context)
    {
        var returnString = "";
        foreach (Record record in input.Records) {
            var request = new GetObjectRequest()
            {
                BucketName = record.s3.bucket.name,
                Key = record.s3.@object.key
            };

            using (var res = S3Client.GetObjectAsync(request))
            {
                StreamReader sReader = new StreamReader(res.Result.ResponseStream); //Time out here
                // string? line = sReader.ReadLine();
                // Console.WriteLine(line);

                while (!sReader.EndOfStream){
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
            }
            returnString += $"Successfully read {record.s3.bucket.name}/{record.s3.@object.key}.";

            // TODO: do something with this parsed data via database
        }
        return returnString;
    }
}

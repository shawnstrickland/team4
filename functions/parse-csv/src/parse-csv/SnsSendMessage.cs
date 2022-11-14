using System;
using System.Linq;
using System.Threading.Tasks;

using Amazon;
using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;

public class SnsSendMessage
{
    public async Task Send(string topic, string someOtherMessage)
    {
        /* Topic ARNs must be in the correct format:
            *   arn:aws:sns:REGION:ACCOUNT_ID:NAME
            *
            *  where:
            *  REGION     is the region in which the topic is created, such as us-west-2
            *  ACCOUNT_ID is your (typically) 12-character account ID
            *  NAME       is the name of the topic
            */
        string topicArn = topic;
        string message = "Hello at " + DateTime.Now.ToShortTimeString() + someOtherMessage;

        var client = new AmazonSimpleNotificationServiceClient(region: Amazon.RegionEndpoint.USEast1);

        var request = new PublishRequest
        {
            Message = message,
            TopicArn = topicArn
        };

        try
        {
            Console.WriteLine("Writing to topic: " + topicArn);
            var response = await client.PublishAsync(request);

            Console.WriteLine("Message sent to topic:");
            Console.WriteLine(message);
        }
        catch (Exception ex)
        {
            Console.WriteLine("Caught exception publishing request:");
            Console.WriteLine(ex.Message);
        }
    }
}

using Amazon;
using Amazon.S3;
using Amazon.S3.Transfer;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System.IO;
using System.Threading.Tasks;

namespace WebApplication5.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IConfiguration _configuration;

        public HomeController(ILogger<HomeController> logger, IConfiguration iConfiguration)
        {
            _logger = logger;
            _configuration = iConfiguration;
        }

        public IActionResult Index()
        {
            return View();
        }


        [HttpPost]
        public async Task<IActionResult> UploadFileToS3(IFormFile file)
        {
            //protected readonly IOptions<AppSettings> _iOptions = 

            var accessKeyID = _configuration.GetValue<string>("AppSettings:AWSAccessKeyID");
            var secretAccessKey = _configuration.GetValue<string>("AppSettings:AWSSecretAccessKey");
            var sessionToken = _configuration.GetValue<string>("AppSettings:AWSSessionToken");
            var bucketName = _configuration.GetValue<string>("AppSettings:BucketName");

            // You can generate the 'access key id' and 'secret key id, when you create the IAM user in AWS.
            // Region endpoint should be same as the bucket region
            //using (var amazonS3client = new AmazonS3Client("ASIA4BYFEEAIQ7OS367H", "0u5Bdo6DYQBO9i8JPMhIff8H4CCYc0nYAUKw1F/b",
            //"IQoJb3JpZ2luX2VjENv//////////wEaCXVzLWVhc3QtMSJHMEUCICIbj8myIZp4iGkZAItaTnNdR/XlLo3VsHtha7wGzJZSAiEAxMse29Q9mp3JgNGxiZISifyVFuNACbJVUTSeHsPRx/MqpAMIxP//////////ARAAGgw4Mjg0MDI1NzMzMjkiDM4yRwqbL1EewB2/lir4AvBma3uI2cFYfrgOxcZmvMG4ix5Hcltkm4h9n7HEk8EKMgaYpvHuP5eTqXlAOU0AXWvoDAJVWKu1W38bhp2pVfFJngJbrmvE/xPf8oro7j+jyCmdVGO7s25zfFk67ovGLb2Ad1e8xzp56adfeZtTZ5CcuvolVdi+knDe671bJKWe0o3Tjhqxrfj8otBfhZCnBZ1NNX0SpY8sDv5YlZVpzxhth8S2l2DDflyy0nIQBFEFPzYXNbsKF+46iEsOHNxQ+uz5FV3F+zBberBQWTanNjPD+OaUNvMXrNheQa/hkpZMNJVGGA/yiRw9HosepVbkijNEvLdmgd0M0cEsQzeIClMbIHwnp3CBi0N47rvG/74mxQBTUBneTHLi16as0V/1gwF7zK9g0/Wgdd9xwNHlzj432fZsmgkTPd7P0w2Cn/7VYWNIad+UJq69VgesHvXdXzpbnbTJPPxigaZyg/cuqmleegTZq2++25N8txb+JlWQRB+l+nL9waYwqZmQmwY6pgH2lB+AghVSMqhUpJizJNSk9WvlBQrRcbW/KnzPrx6Xc3J1PoltqNJdj1SRhYfuV1W2pLiZj1Yqo4NKUZ4mqtTIQg4u9j4/dMsjpexzctdjqrEEkbYj4XwmhUgjUhzJbVJhCOo36Vn7JXc8n7JUqYtUg0bOCuVtoIX9lzDC7gPB85zfjRJVKyPJHlUtqLU8cJN463KWgwwBdmfOUE5geYcM4249J2uw",
            //RegionEndpoint.USEast1))

            using (var amazonS3client = new AmazonS3Client(accessKeyID, secretAccessKey, sessionToken, RegionEndpoint.USEast1))

            //using (var amazonS3client = new AmazonS3Client("ASIAXEGI2XR4GPZEHTXK", "Tw9wqIbIt2Ny01YNgGn31n7LgwOtASKTNB/esi+Y", 
            //    "IQoJb3JpZ2luX2VjENz//////////wEaCXVzLWVhc3QtMSJGMEQCIDnbVW7+vNs+j+4zGaFHBkYBeLfQCJEH00O1Aq6AI7/TAiA5PYhpMlyz6XpXYPmWSDdIMxq4oNrdY9QBu50V6aEnbiqkAwjE//////////8BEAAaDDQ5MDA0NzQ1NDMyOCIM8XwT/pl8knu71yH8KvgCQAbAYLOZ8EgCvCRLa9cQsP0fXj9S3PgAp2trLlQQoRme3vcSxlpbB4+9+vNtyN50rMfIr3wLjvchtKmZCGU1boPN1f4JDDW9f0IYp9AodwHAY7TJkv0LvlLqViy5LwEmHjD8uaFRXFkSsp6+xmMmHSGF6LUkPW+ayEOmoZ9GkmGMvPdZqlCLGAiliHxc9wFc2/YZQUN09+cf9gO4Ygig22dJwU2bhqcBUvsAMIAsa/WoDPHgc8LBZciDdrXt6efzHVR9JTJGvtcWj0Li3yxNTRIUfj9vq+yxrtFQPw4crUozryYqhoLrnJfJJ9750sNPYPOuxKZgHO32YTski9GXfitzeKU9pUiJ1sOZ43MIpPKd7uF+rCEWMlfEhvJ4H5FsnIm146DdiDTKK6tSHQPjkuaCiInmF8mkQ84fkHMRzx4V0KO0EH8EarrRq7BJmA+jBh4x4Z+y7ImY+oYYbZ+teHySxtL/iHl7zN9cX0o2VaYRXAjQu8n0yTC9o5CbBjqnAbCcKVWlCbT3o9Rhc4QZUmbyY5EgfrxTRF7SgYeglphTYoO7Sv/IAHrpfKKYrx01qTZjGzhB/obNHdJwPNmpGIgoBqrtnvaTW07uU4M4lqQLFLZ45Vz3UTmU7cFyDnxobYNPrmnUVwx720moiGC4j6rIE20DeQQWAyxUa8xK2Hl6VRfJHmhF2DVeQh+AZCZzQ5zd3P9Sp3M+ys4fjs7LUNpnnTM/4rYP", 
            //    RegionEndpoint.USEast1))
            {
                using (var memoryStream = new MemoryStream())
                {
                    // Copy file content to memory stream
                    file.CopyTo(memoryStream);
                    // Create request with file name, bucket name and file content/memory stream
                    var request = new TransferUtilityUploadRequest
                    {
                        InputStream = memoryStream,
                        // File name
                        Key = file.FileName,
                        // S3 bucket name
                        BucketName = bucketName,
                        //BucketName = "tuyen-test",
                        // File content type
                        ContentType = file.ContentType
                    };

                    var transferUtility = new TransferUtility(amazonS3client);
                    await transferUtility.UploadAsync(request);
                }
            }
            ViewBag.Success = "The File has been uploaded successfully on S3 bucket";
            return View("Index");
        }

    }
}
using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace functionapp_keyvaultreference
{
    public static class akvbug
    {
        [FunctionName("akvbug")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            string result = Environment.GetEnvironmentVariable("bug");
            return !string.IsNullOrWhiteSpace(result) 
                ? new OkObjectResult(result) 
                : new NotFoundObjectResult("Environment variable is null or whitespace") as IActionResult;
        }
    }
}

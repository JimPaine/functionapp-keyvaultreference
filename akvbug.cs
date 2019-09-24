using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.KeyVault;

namespace functionapp_keyvaultreference
{
    public static class akvbug
    {
        [FunctionName("akvbug")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            string goDirect = req.Query["goDirect"];

            string result = goDirect == "false" || string.IsNullOrWhiteSpace(goDirect)
            ? Environment.GetEnvironmentVariable("bug")
            : GetSecret();

            return !string.IsNullOrWhiteSpace(result) 
                ? new OkObjectResult(result) 
                : new NotFoundObjectResult("Environment variable is null or whitespace") as IActionResult;
        }

        private static string GetSecret()
        {
            KeyVaultClient keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(new AzureServiceTokenProvider().KeyVaultTokenCallback));
            return keyVaultClient.GetSecretAsync(Environment.GetEnvironmentVariable("secretUri")).Result.Value;
        }
    }
}

# Hardened Web App

This example scenario describes how to set up an [Azure Web App](https://docs.microsoft.com/azure/app-service/) within a network environment that enforces strict policies regarding inbound and outbound network flows. In such cases, the Web App may not be directly exposed to the internet but will instead require all traffic to go through an [Azure Firewall](https://docs.microsoft.com/azure/firewall/) or third-party network virtual appliance.

The example shows a scenario in which a web application is protected with [Azure Front Door](https://docs.microsoft.com/azure/frontdoor/), an Azure Firewall and connects securely to an [Azure SQL Databases](https://docs.microsoft.com/azure/azure-sql/).

The solution is comprised of several [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/) files that deploy the required infrastucture.

The ```main.bicep``` deploys the base infrastructure using Bicep modules from the following files
- ```network.bicep```
- ```webapp.bicep```
- ```firewall.bicep```
- ```sql.bicep```
- ```frontdoor.bicep```
- ```routetable.bicep```
- ```nsg.bicep```
- ```nsgrules.bicep```

1. [Install Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)


2. Deploy ```main.bicep``` using either [Azure PowerShell](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install#azure-powershell) or [Azure CLI](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install#azure-cli). The bicep file has pre-configured parameters for deploying all resources.
The parameter ```usePreviewFeatures```, set to ```true``` by default, enables deployment of a Network Security Group associated with the subnet that will host the Web App Private Endpoint. This restricts allowed incoming traffic to the Azure Firewall subnet alone by leveraging the [Private Endpoint support for NSGs (preview)](https://azure.microsoft.com/en-us/updates/public-preview-of-private-link-network-security-group-support/) feature. Set the parameter to ```false``` if you do not wish to leverage the preview feature in your deployment.

If using PowerShell, deploy the resources with:

```powershell
New-AzResourceGroupDeployment -ResourceGroupName [resourceGroupName] -Name [deploymentName] -TemplateFile .\main.bicep
```

You will be asked to provide the parameters ```customBackendFqdn``` and ```sqladministratorLoginPassword``` upon deployment.

2. Take note of the Public IP Address assigned to the Azure Firewall after creation. The IP is also provided as output of the deployment of main.bicep.

![Public IP](./img/publicip.png)

3. Take note of the Custom Domain Verification ID of the Web App you just created. The Custom Domain Verification ID is also provided as output of the deployment of main.bicep.

![Custom Domain Verification ID](./img/domainid.png)

4. Take note of the Azure SQL Server name you just created. The FQDN of the Azure SQL Server is also provided as output of the deployment of main.bicep.

![SQL Server name](./img/sql.png)

5. Sign in to the website of your domain provider.
---
**NOTE**
Every domain provider has its own DNS records interface, so consult the provider's documentation. Look for areas of the site labeled Domain Name, DNS, or Name Server Management.
Often, you can find the DNS records page by viewing your account information and then looking for a link such as My domains. Go to that page, and then look for a link that's named something like Zone file, DNS Records, or Advanced configuration.
---

6. Create an A record with the Public IP you just obtained

The following screenshot is an example of a DNS records page with the A record created:

![DNS records page](./img/dnsrecords1.png)

---
**NOTE**
If you like, you can use Azure DNS to manage DNS records for your domain and configure a custom DNS name for Azure App Service. For more information, see [Tutorial: Host your domain in Azure DNS](https://docs.microsoft.com/azure/dns/dns-delegate-domain-azure-dns).
---

7. Create a TXT record with the Custom Domain Verification ID of the Web App you just deployed. This will allow you to reuse the custom FQDN record you just created an A record for and add it to the Web App in the following steps.

The TXT record must be created in the format ```asuid.<subdomain>``` For example, if your custom FQDN is ```backend.contoso.com``` you would create the record:

```asuid.backend.contoso.com TXT [DOMAIN VERIFICATION ID]```

For more information, see [Tutorial: Map an existing custom DNS name to Azure App Service - Create the DNS records](https://docs.microsoft.com/Azure/app-service/app-service-web-tutorial-custom-domain?tabs=cname#4-create-the-dns-records)

The following screenshot is an example of a DNS records page with the TXT record created:

![DNS records page](./img/dnsrecords2.png)

8. Map the custom domain to the Web App you just created. For more information, see [Tutorial: Map an existing custom DNS name to Azure App Service - Get a domain verification ID](https://docs.microsoft.com/Azure/app-service/app-service-web-tutorial-custom-domain?tabs=cname#3-get-a-domain-verification-id)

9. Upload a SSL certificate matching your custom FQDN to your Web App. For more information, see [Tutorial: Secure a custom DNS name with a TLS/SSL binding in Azure App Service](https://docs.microsoft.com/Azure/app-service/configure-ssl-bindings)

10. Your Web App should now be reachable with the public FQDN of the Azure Front Door instance.

**Optional Steps**

11. If you'd like, you can also [bind a custom FQDN domain to Azure Front Door](https://docs.microsoft.com/azure/frontdoor/front-door-custom-domain) and [configure HTTPS for the custom domain](https://docs.microsoft.com/azure/frontdoor/front-door-custom-domain-https)

12. You can verify that connectivity from the Web App to the Azure SQL Server is happening over a private channel by creating a [Virtual Machine](https://docs.microsoft.com/azure/virtual-machines/) **in the same Virtual Network** used for the scenario. 
    - Log into the Virtual Machine and browse to ```https://<webappname>.scm.azurewebsites.net``` where you will access the [Kudu diagnostic console](https://docs.microsoft.com/azure/app-service/resources-kudu)
    - Log in and in the top bar click on ```Debug console --> CMD```
    - Type the command ```nameresolver <sqlname>.database.windows.net```, using the Azure SQL Server name you retrieved in Step 4.

You should see that the Azure SQL Server instance name is being resolved with a private IP.

The following screenshot is an example of DNS resolution of the Azure SQL Server instance from the Kudu console:

![Kudu console](./img/kudu.png)

13. You can also verify that outbound traffic from the Web App is going through the Azure Firewall by typing the following command in the Kudu console:
    - ```curl -s ifconfig.co```

The output should match the public IP address of the Azure Firewall you retrieved in Step 2.

The following screenshot is an example from the Kudu console:

![Kudu console](./img/outbound.png)

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

# Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content
in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all other rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.

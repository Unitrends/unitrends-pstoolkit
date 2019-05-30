Get-ChildItem $psscriptroot\Modules\*.ps1 | % { 
#	Write-Host $_.FullName 
	. $_.FullName
}

	# ignore certs for https
	add-type @"
	    using System.Net;
	    using System.Security.Cryptography.X509Certificates;
	    public class TrustAllCertsPolicy : ICertificatePolicy {
	        public bool CheckValidationResult(
	            ServicePoint srvPoint, X509Certificate certificate,
	            WebRequest request, int certificateProblem) {
	            return true;
	        }
	    }
"@
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls12

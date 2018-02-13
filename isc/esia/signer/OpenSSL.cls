Class isc.esia.signer.OpenSSL Extends (isc.esia.signer.Abstract, isc.util.ESIAUtils)
{

Parameter NAME = "OpenSSL";

/// zw ##class(isc.esia.OpenSSL).sign("13","C:\InterSystems\esiatest.crt","C:\InterSystems\esiatestNP.key", .out)
ClassMethod sign(text As %String, Output out As %String) As %Status
{
	set sc = ..createFile(.textFile,,text)
	set outFile = ##class(%File).TempFilename()
	
	set cmd = $$$FormatText("%1 smime -sign -md sha256 -in %2 -signer %3 -inkey %4 -out %5 -outform DER", ..getOpenSSL(), textFile, ..getCertificate(), ..getKey(), outFile)
	
	set sc = ..execute(cmd)

	quit:$$$ISERR(sc) sc
	
	set sc = ..fileToString(outFile, .out)
	quit:$$$ISERR(sc) sc
	
	set sc = ..deleteFile(textFile)		
	quit sc
}

/// Путь до приватного ключа
ClassMethod getKey() As %String [ CodeMode = expression ]
{
"C:\InterSystems\esiatestNP.key"
}

/// Путь до сертификата
ClassMethod getCertificate() As %String [ CodeMode = expression ]
{
"C:\InterSystems\esiatest.crt"
}

ClassMethod getOpenSSL() [ CodeMode = expression ]
{
"openssl"
}

}


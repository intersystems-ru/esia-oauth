Class isc.esia.signer.OpenSSL Extends (isc.esia.signer.Abstract, isc.util.ESIAUtils)
{

Parameter NAME = "OpenSSL";

/// Подписать text.
/// out - подпись.
/// zw ##class(isc.esia.signer.OpenSSL).sign("13", .out)
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

/// Проверить подпись
ClassMethod verify(text As %String, signature As %String) As %Status
{
	#dim sc,sc1,sc2 As %Status = $$$OK
	set sc = ..createFile(.textFile,,text)
	quit:$$$ISERR(sc) sc
	set sc = ..createFile(.signatureFile,,signature)
	quit:$$$ISERR(sc) sc
	
	set outFile = ##class(%File).TempFilename()
	
	set cmd = $$$FormatText("%1 dgst -verify %2 -signature %3 %4 > %5 2>&1", ..getOpenSSL(), ..getESIAPKey(), signatureFile, textFile, outFile)
	
	set sc = ..execute(cmd)
	
	set sc1 = ..fileToString(outFile, .out)

	if $zstrip(out,"<>E'A")'="Verified OK" {
		set sc2 = $$$ERROR($$$GeneralError, "Ошибка валидации подписи: " _ out)
	}
	
	set sc = $$$ADDSC(sc, $$$ADDSC(sc1, sc2))
	quit:$$$ISERR(sc) sc
	
	set sc = ..deleteFile(textFile)
	set sc = ..deleteFile(signatureFile)
	
	quit sc
}

/// Путь до приватного ключа
ClassMethod getKey() As %String [ CodeMode = expression ]
{
"C:\InterSystems\esiatest.key"
}

/// Путь до сертификата
ClassMethod getCertificate() As %String [ CodeMode = expression ]
{
"C:\InterSystems\esiatest.crt"
}

/// Путь до публичного ключа ЕСИА
ClassMethod getESIAPKey() As %String [ CodeMode = expression ]
{
"C:\InterSystems\esiapublic.pem"
}

/// Путь до OpenSSL
ClassMethod getOpenSSL() [ CodeMode = expression ]
{
"openssl"
}

/// Протестировать проверку ответа.
/// do ##class(isc.esia.signer.OpenSSL).testVerify()
ClassMethod testVerify()
{
	set code = "eyJ2ZXIiOjEsInR5cCI6IkpXVCIsInNidCI6ImF1dGhvcml6YXRpb25fY29kZSIsImFsZyI6IlJTMjU2In0.eyJuYmYiOjE1MTg0MzQ3MjYsInNjb3BlIjoiZnVsbG5hbWU_b2lkPTEwMDAzMzA3OTkiLCJhdXRoX3RpbWUiOjE1MTg0MzQ3MjU4NzcsImlzcyI6Imh0dHA6XC9cL2VzaWEuZ29zdXNsdWdpLnJ1XC8iLCJ1cm46ZXNpYTpzaWQiOiIyNjhkYTEzYmFjYjM0MjM4MGRiY2FmYzE2NjdmMDQ3M2FmODY5NGNjY2MxNGViN2I2ZGQ4Yjg3MmEyNDkwOWY2IiwidXJuOmVzaWE6Y2xpZW50OnN0YXRlIjoiMDZmNzRkYzQtNWZiZC00ODljLWI1ZDYtZGU1NjQ5ZmZiODg1IiwiYXV0aF9tdGhkIjoiUFdEIiwidXJuOmVzaWE6c2JqIjp7InVybjplc2lhOnNiajp0eXAiOiJQIiwidXJuOmVzaWE6c2JqOm9pZCI6MTAwMDMzMDc5OSwidXJuOmVzaWE6c2JqOm5hbSI6Ik9JRC4xMDAwMzMwNzk5IiwidXJuOmVzaWE6c2JqOmVpZCI6NzQ0NTQyMX0sImV4cCI6MTUxOTk1MzIyMTE2MiwicGFyYW1zIjp7fSwiaWF0IjoxNTE4NDM0NzI2LCJjbGllbnRfaWQiOiIxMjI3MDEifQ.JdgYTNtgyplAIG3URTxdMIqr0mXdsok9okxTHVfDRq28_7FSiytZV-KDixxH99c_EWx0HOsRCOlcBwD32oL9ou1bQadWGyga9lsRt1A78aAV4W7ewnL7a_uQDBVZROzx6R-PPfdqWuwcR0vCjCUSEqqCUh97WauV3N3PyI1RJLbaup2cqKsYhPcB1o4iqwVyCmvCTkZOKsFI6DFrRbVyXFEH1Xuo5QB2_EJkcoA7RHhTa9KbJy4K1Z2T0wdwO0l2ddg13sXq-kdXzJk9BpW9EsAnyB6zv2uCDHUd8MSo7JbjEcxVby165Xaj3ZDoAh_CdrqjNhCgFdFiKjogJGY0gw"
	set text = $piece(code, ".", 1, 2)
	set base64Signature = $piece(code, ".", 3)
	set signature = ..base64URLDecode(base64Signature)
	
	set sc = ..verify(text, signature)
	if $$$ISERR(sc) { 
		write $System.Status.GetErrorText(sc)
	} else {
		write "Verified OK"
	}
}

}


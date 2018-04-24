Class isc.esia.signer.GOSTOpenSSL Extends isc.esia.signer.OpenSSL
{

Parameter NAME = "GOST OpenSSL";

/// Подписать text.
/// out - подпись.
/// zw ##class(isc.esia.signer.OpenSSL).sign("13", .out)
ClassMethod sign(text As %String, Output out As %String) As %Status
{
	set textFile = ..#DIR _ "OpenSSLdata.txt"
	set sc = ..createFile(textFile,,text)
	set outFile = ..#DIR _ "OpenSSL.sig"
	 						// out32\openssl cms -sign -inkey private2.key -in file.txt -signer Pashinova2019.pem -engine gost -out test.sign -outform DER -noattr -binary
	set cmd = $$$FormatText("%1 cms -sign -in %2 -signer %3 -engine gost -inkey %4 -out %5 -outform DER -noattr -binary", ..getOpenSSL(), textFile, ..getCertificate(), ..getKey(), outFile)
	
	set sc = ..execute(cmd)

	quit:$$$ISERR(sc) sc
	
	set sc = ..fileToString(outFile, .out, 0)
	quit:$$$ISERR(sc) sc
	
	//set out = $zcvt(out, "I", "UTF8")
	
	//set sc = ..deleteFile(textFile)		
	quit sc
}

/// Проверить подпись
ClassMethod verify(text As %String, signature As %String) As %Status
{
	quit $$$OK
	#dim sc,sc1,sc2 As %Status = $$$OK
	set sc = ..createFile(.textFile,,text)
	quit:$$$ISERR(sc) sc
	set sc = ..createFile(.signatureFile,,signature)
	quit:$$$ISERR(sc) sc
	
	set outFile = ##class(%File).TempFilename()
	
	set cmd = $$$FormatText("%1 dgst -engine gost -verify %2 -signature %3 %4 > %5 2>&1", ..getOpenSSL(), ..getESIAPKey(), signatureFile, textFile, outFile)
	
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
"C:\InterSystems\privkey\private2.key"
}

/// Путь до сертификата
ClassMethod getCertificate() As %String [ CodeMode = expression ]
{
"C:\InterSystems\privkey\Pashinova2019.pem"
}

/// Путь до публичного ключа ЕСИА
/// TODO. Пока что PKey сертификата
ClassMethod getESIAPKey() As %String [ CodeMode = expression ]
{
"C:\InterSystems\privkey\public.pem"
}

/// Путь до OpenSSL
ClassMethod getOpenSSL() [ CodeMode = expression ]
{
"C:\InterSystems\privkey\out32\openssl.exe"
}

/// do ##class(isc.esia.signer.GOSTOpenSSL).test()
ClassMethod test()
{
	set text = "fullname birthdate gender snils email mobile contacts usr_org http://esia.gosuslugi.ru/org_shortname?org_oid=1000298922 http://esia.gosuslugi.ru/org_fullname?org_oid=1000298922 http://esia.gosuslugi.ru/org_type?org_oid=1000298922 http://esia.gosuslugi.ru/org_ogrn?org_oid=1000298922 http://esia.gosuslugi.ru/org_inn?org_oid=1000298922 http://esia.gosuslugi.ru/org_leg?org_oid=1000298922 http://esia.gosuslugi.ru/org_kpp?org_oid=1000298922 http://esia.gosuslugi.ru/org_agencyterrange?org_oid=1000298922 http://esia.gosuslugi.ru/org_agencytype?org_oid=1000298922 http://esia.gosuslugi.ru/org_oktmo?org_oid=1000298922 http://esia.gosuslugi.ru/org_grps?org_oid=1000298922 http://esia.gosuslugi.ru/org_emps?org_oid=10002989222018.03.29 06:57:29 +0000122701147b0835-43d5-4682-aa80-bac4a37682b3"
	set sc = ..sign(text, .signature)
	w:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	
	set sc = ..verify(text, signature)
	if $$$ISERR(sc) {
		w !,$System.Status.GetErrorText(sc)
	} else {
		w !,"Verified OK"
	}
}

}


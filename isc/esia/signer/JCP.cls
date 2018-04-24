Class isc.esia.signer.JCP Extends (isc.esia.signer.Abstract, isc.util.ESIAUtils)
{

Parameter NAME = "КриптоПРО JCP";

/// Подписать запрос.
ClassMethod sign(text As %String, Output out As %String) As %Status
{
	set textStream = ##class(%Stream.GlobalBinary).%New()
	do textStream.Write(text)
	
	#dim outStream As %Stream.GlobalBinary
	set sc = ##class(isc.jcp.JcpUtils).createCMSSignature(textStream, .outStream,..getCertificate())
	quit:$$$ISERR(sc) sc
	
	set out = outStream.Read()

	//set sc = ..createFile(..#DIR _ "JCP.sig",,outStream)
	//set sc = ..createFile(..#DIR _ "JCPdata.txt",,text)
	quit $$$OK
}

/// Проверить подпись
/// Проверяет нашу подпись
ClassMethod verify(text As %String, signature As %String) As %Status
{
	//set ^dbg2 = $lb(text, signature)
	//quit $$$OK
	set textStream = ##class(%Stream.GlobalBinary).%New()
	do textStream.Write(text)
	
	set signatureStream = ##class(%Stream.GlobalBinary).%New()
	do signatureStream.Write(signature)
	set sc = ##class(isc.jcp.JcpUtils).verifyCMSSignature(signatureStream, textStream,..getCertificate())
	
	quit sc
}

/// Путь до сертификата
ClassMethod getCertificate() As %String [ CodeMode = expression ]
{
"C:\InterSystems\Pashinova2019.cer"
}

/// Путь до публичного ключа ЕСИА
ClassMethod getESIAPKey() As %String [ CodeMode = expression ]
{
""
}

/// do ##class(isc.esia.signer.JCP).test()
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


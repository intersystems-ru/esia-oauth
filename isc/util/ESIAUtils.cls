Class isc.util.ESIAUtils
{

/// Кодирование в base64url
ClassMethod base64URLDecode(text) As %String
{
	set text = $translate(text, "-_", "+/")
	set text = text _ $case($l(text)#4, 2: "==", 3: "=", :"")
	quit $system.Encryption.Base64Decode(text)
}

/// Декодирование из base64url
ClassMethod base64URLEncode(text) As %String
{
	set text = $system.Encryption.Base64Encode(text, 1)
	set text = $translate(text, "+/=", "-_")
	quit text
}

/// Создать файл name. 
/// Если name не задан, то возвращается имя созданного файла (в папке Temp). 
/// Если name - расширение, то возвращается имя созданного файла (в папке Temp) с заданным расширением.
/// stream - стрим файла
/// content - строка или stream который записывается в файл
ClassMethod createFile(ByRef name As %String = "", Output stream As %Stream.FileBinary, content As %String) As %String
{
	#dim sc As %Status = $$$OK
	
	if name="" {
		set name = ##class(%File).TempFilename()
	} elseif $length(name, ".")=1 {
		set name = ##class(%File).TempFilename(name)
	}
	
	set stream = ##class(%Stream.FileBinary).%New()
	set sc = stream.LinkToFile(name)
	
	if $data(content) {
		if $isObject(content) {
			set sc = stream.CopyFrom(content)
		} else {
			set sc = stream.Write(content)
		}
		quit:$$$ISERR(sc) sc
		set sc = stream.%Save()
		do stream.Rewind()
	}
	
	quit sc
}

/// Прочитать файл в строку
ClassMethod fileToString(name As %String, Output content As %String, delete As %Boolean = {$$$YES}) As %Status
{
	#dim sc As %Status = $$$OK
	set stream = ##class(%Stream.FileBinary).%New()
	set sc = stream.LinkToFile(name)
	
	set content = stream.Read($$$MaxStringLength)
	
	if delete {
		kill stream
		set sc = ..deleteFile(name)
	}
	
	quit sc
}

/// Удалить файл
ClassMethod deleteFile(name As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set success = ##class(%File).Delete(name, .code)
	set:success'=$$$YES sc = $$$ERROR($$$GeneralError, $$$FormatText("Error deleting file %1 with code %2", name, code))
	quit sc
}

/// Выполнить команду ОС
ClassMethod execute(cmd, debug As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set code = ""
	//set out = ""
	write:debug !, "cmd: ", cmd
	//set sc = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code)
	set code = $zf(-1, cmd)
	write:debug !,"code: ", code
	
	if code'=0 {
		set sc1 = $$$ERROR($$$GeneralError, $$$FormatText("Комманда ОС: `%1` завершилась с кодом: `%2`", cmd, code))
		set sc = $$$ADDSC(sc, sc1)	
	}
	return sc
}

/// Создать SSL конфигурацию. TODO: клиентский сертификат?
/// w $System.Status.GetErrorText(##class(isc.util.ESIAUtils).createSSLConfig())
ClassMethod createSSLConfig(sslConfig As %String = {##class(isc.esia.configuration.Abstract).#SSLCONFIG}) As %Status
{
	#dim sc As %Status = $$$OK
	new $namespace
	set $namespace = "%SYS"
	
	set:'##class(Security.SSLConfigs).Exists(sslConfig) sc = ##class(Security.SSLConfigs).Create(sslConfig)
	quit sc
}

/// Создать веб-приложение
/// w $System.Status.GetErrorText(##class(isc.util.ESIAUtils).сreateWebApp())
ClassMethod сreateWebApp(appName As %String = "/esia") As %Status
{
	set:$e(appName)'="/" appName = "/" _ appName
	#dim sc As %Status = $$$OK
	new $namespace
	set namespace = $namespace
	set $namespace = "%SYS"
	
	set props("AutheEnabled") = $$$AutheUnauthenticated
	set props("NameSpace") = namespace
	set props("IsNameSpaceDefault") = $$$NO
	set props("DispatchClass") = "isc.esia.OAuthREST"
	set sc = ##class(Security.Applications).Create(appName, .props)
	quit sc
}

/// Удалить данные пакета isc.esia.data.
/// do ##class(isc.util.ESIAUtils).purgeData()
ClassMethod purgeData()
{
	do ##class(isc.esia.data.Person).%KillExtent()
	do ##class(isc.esia.data.Token).%KillExtent()
}

}


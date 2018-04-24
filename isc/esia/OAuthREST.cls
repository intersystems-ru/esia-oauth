Class isc.esia.OAuthREST Extends (%CSP.REST, isc.util.ESIAUtils)
{

Parameter HandleCorsRequest = 0;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/login" Method="GET" Call="initialLogin"/>
<Route Url="/loginResponse" Method="GET" Call="loginResponse"/>

<Route Url="/logout" Method="GET" Call="initialLogout"/>
<Route Url="/logoutResponse" Method="GET" Call="logoutResponse"/>
</Routes>
}

/// Первоначальная точка входа для авторзации пользователя через ЕСИА
ClassMethod initialLogin() As %Status
{
	#dim %response As %CSP.Response
	set %response.Redirect = $classmethod(##class(isc.esia.Settings).getSetting("config"), "getLoginURL")
	quit $$$OK
}

/// Метод вызывается из ЕСИА через redirect - в ответ на логин из нашего портала
/// do ##class(isc.esia.OAuthREST).decode()
ClassMethod loginResponse(debug As %Boolean = {$$$YES})
{
	#dim sc As %Status = $$$OK
	#dim %request As %CSP.Request
	#dim %response As %CSP.Response
	
	set code = %request.Get("code")
	set state = %request.Get("state")

	set header = ..base64URLDecode($p(code, "."))
	set payload = ..base64URLDecode($p(code, ".", 2))
	set signature = ..base64URLDecode($p(code, ".", 3))
	
	set verifier = ##class(isc.esia.Settings).getSetting("signer")
	
	set sc = $classmethod(verifier, "verify", $piece(code, ".", 1, 2), signature)
	quit:$$$ISERR(sc) sc
	
	set config = ##class(isc.esia.Settings).getSetting("config")
	set sc = $classmethod(config, "sendTokenRequest", code, .tokenResponse)
	quit:$$$ISERR(sc) sc
	
	write:debug !, "Token response:",!,!
	zw:debug tokenResponse
	
	set payloadObj = {}.%FromJSON(payload)
	set oid = payloadObj."urn:esia:sbj"."urn:esia:sbj:oid"
	
	#dim tokenObj As isc.esia.data.Token
	set tokenObj = ##class(isc.esia.data.Token).fromJSON(tokenResponse)
		
	set sc = $classmethod(config, "sendDataRequest", tokenObj.accessToken, oid, .data)
	quit:$$$ISERR(sc) sc
	
	write:debug !, "Data response:",!,!
	
	#dim person As isc.esia.data.Person
	
	if ##class(isc.esia.data.Person).oidIndexExists(oid, .id) {
		set person = ##class(isc.esia.data.Person).%OpenId(id)
		do person.updateFromJSON(data)
	} else {
		set person = ##class(isc.esia.data.Person).fromJSON(data)
		set person.oid = oid
	}
	set person.token = tokenObj

	zw:debug data
	
	set sc = person.%Save()
	if $$$ISERR(sc) {
		zw:debug person
		write:debug $System.Status.GetErrorText(sc)
		quit sc
	}
	
	set orgId = person.organizations.GetAt(1)
	zw:debug orgId

	set sc = $classmethod(config, "sendGroupsRequest", tokenObj.accessToken, orgId, oid, .groups)
	do person.setGroups({}.%FromJSON(groups))
	zw:debug person
	
	do person.setSession()
	
	// авторизация
    if '..isAuthorized()
    {
	    kill %session.Data
    	quit ..initialLogout()
    }

	set redirect = $parameter(config, "MAINPAGE")
	if debug {
		write !, "Redirect: ", redirect,!
	} else {
		set %response.Redirect = redirect
	}
	
	quit sc
}

/// Специфические проверки данных в %session.Data + принятие решения об авторизации
ClassMethod isAuthorized() As %Boolean
{
	quit $$$YES
}

/// Первоначальная точка входа для выхода пользователя через ЕСИА
ClassMethod initialLogout() As %Status
{
	#dim %response As %CSP.Response
	set %response.Redirect = $classmethod(##class(isc.esia.Settings).getSetting("config"), "getLogoutURL")
	quit $$$OK
}

/// Метод вызывается из ЕСИА через redirect - в ответ на выход из нашего портала
ClassMethod logoutResponse() As %Status
{
	set %response.Redirect = $parameter(##class(isc.esia.Settings).getSetting("config"), "PUBLICPAGE")
	set %session.EndSession = $$$YES
	quit $$$OK
}

}


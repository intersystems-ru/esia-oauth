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
	//set code = "eyJ2ZXIiOjEsInR5cCI6IkpXVCIsInNidCI6ImF1dGhvcml6YXRpb25fY29kZSIsImFsZyI6IlJTMjU2In0.eyJuYmYiOjE1MTg0MzQ3MjYsInNjb3BlIjoiZnVsbG5hbWU_b2lkPTEwMDAzMzA3OTkiLCJhdXRoX3RpbWUiOjE1MTg0MzQ3MjU4NzcsImlzcyI6Imh0dHA6XC9cL2VzaWEuZ29zdXNsdWdpLnJ1XC8iLCJ1cm46ZXNpYTpzaWQiOiIyNjhkYTEzYmFjYjM0MjM4MGRiY2FmYzE2NjdmMDQ3M2FmODY5NGNjY2MxNGViN2I2ZGQ4Yjg3MmEyNDkwOWY2IiwidXJuOmVzaWE6Y2xpZW50OnN0YXRlIjoiMDZmNzRkYzQtNWZiZC00ODljLWI1ZDYtZGU1NjQ5ZmZiODg1IiwiYXV0aF9tdGhkIjoiUFdEIiwidXJuOmVzaWE6c2JqIjp7InVybjplc2lhOnNiajp0eXAiOiJQIiwidXJuOmVzaWE6c2JqOm9pZCI6MTAwMDMzMDc5OSwidXJuOmVzaWE6c2JqOm5hbSI6Ik9JRC4xMDAwMzMwNzk5IiwidXJuOmVzaWE6c2JqOmVpZCI6NzQ0NTQyMX0sImV4cCI6MTUxOTk1MzIyMTE2MiwicGFyYW1zIjp7fSwiaWF0IjoxNTE4NDM0NzI2LCJjbGllbnRfaWQiOiIxMjI3MDEifQ.JdgYTNtgyplAIG3URTxdMIqr0mXdsok9okxTHVfDRq28_7FSiytZV-KDixxH99c_EWx0HOsRCOlcBwD32oL9ou1bQadWGyga9lsRt1A78aAV4W7ewnL7a_uQDBVZROzx6R-PPfdqWuwcR0vCjCUSEqqCUh97WauV3N3PyI1RJLbaup2cqKsYhPcB1o4iqwVyCmvCTkZOKsFI6DFrRbVyXFEH1Xuo5QB2_EJkcoA7RHhTa9KbJy4K1Z2T0wdwO0l2ddg13sXq-kdXzJk9BpW9EsAnyB6zv2uCDHUd8MSo7JbjEcxVby165Xaj3ZDoAh_CdrqjNhCgFdFiKjogJGY0gw"

	set header = ..base64URLDecode($p(code, "."))
	set payload = ..base64URLDecode($p(code, ".", 2))
	set signature = ..base64URLDecode($p(code, ".", 3))
	
	set config = ##class(isc.esia.Settings).getSetting("config")
	
	/*do ##class(isc.util.ESIAUtils).createFile("C:\InterSystems\Cache\mgr\Temp\resp.txt", , $p(code, ".", 1, 2))
	do ##class(isc.util.ESIAUtils).createFile("C:\InterSystems\Cache\mgr\Temp\sig.txt", , signature)
	zzdump signature
	w !,!,!
	zzdump $e($p(code, ".", 1, 2),1,100)
	w !,!
	write:debug "Auth response:",!,!
	zw:debug header, payload ///, signature*/
	
	set sc = $classmethod(config, "sendTokenRequest", code, .tokenResponse)
	quit:$$$ISERR(sc) sc
	
	write:debug !, "Token response:",!,!
	zw:debug tokenResponse
	
	set payloadObj = {}.%FromJSON(payload)
	set oid = payloadObj."urn:esia:sbj"."urn:esia:sbj:oid"
	
	#dim tokenObj As isc.esia.data.Token
	set tokenObj = ##class(isc.esia.data.Token).fromJSON(tokenResponse)
	
	zw:debug oid,tokenObj
	
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

	zw:debug data, person
	
	set key = ""
	while 1 {
		set contact = person.contacts.GetNext(.key)
		quit:key=""
		zw:debug contact
	} 

	set sc = person.%Save()
	
	set redirect = $parameter(##class(isc.esia.Settings).getSetting("config"), "MAINPAGE")
	if debug {
		write !, "Reditect: ", redirect,!
	} else {
		set %response.Redirect = redirect
	}
	quit sc
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


/// Абстрактная конфигурация приложения.
Class isc.esia.configuration.Abstract
{

/// Имя конфигурации (опционально)
Parameter NAME;

/// Адрес стартовой страницы портала для перенаправления браузера после выхода
Parameter PUBLICPAGE;

/// Адрес основной страницы портала, на которую направляется браузер после успешного логина
Parameter MAINPAGE;

/// Идентификатор системы-клиента (мнемоника системы в ЕСИА)
Parameter CLIENTID;

/// Сервер ЕСИА
Parameter SERVER;

/// Область доступа, т.е. запрашиваемые права; например, если система-клиент
/// запрашивает доступ к сведениям о сотрудниках организации, то scope должна иметь
/// значение http://esia.gosuslugi.ru/org_emps (с необходимыми параметрами); если
/// запрашивается scope id_doc61 (данные о пользователе), то не нужно в качестве параметра
/// указывать oid этого пользователя.
Parameter SCOPE;

/// *** ПАРАМЕТРЫ ОДИНАКОВЫЕ ДЛЯ БОЛЬШИНСТВА КОНФИГУРАЦИЙ ***
/// 
/// Тип ответа, который ожидается от ЕСИА, имеет значение code,
/// поскольку система-клиент должна получить авторизационный код.
Parameter RESPONSETYPE = "code";

/// Используемая модель контроля доступа; принимает значение “token”,
/// если происходит безусловное наделения системы-клиента полномочиями;
Parameter TOKENRESPONSETYPE = "token";

/// Тип запрашиваемого маркера, в настоящее время ЕСИА поддерживает
/// только значение “Bearer”
Parameter TOKENTYPE = "Bearer";

/// Принимает значение "offline", если требуется иметь доступ к ресурсам и
/// тогда, когда владелец не может быть вызван (в этом случае выпускается маркер
/// обновления); значение “online” – доступ требуется только при наличии владельца.
Parameter ACCESSTYPE = "online";

/// Принимает значение “client_credentials”, если используется модель
/// контроля доступа на основе полномочий системы-клиента;
/// Принимает значение "authorization_code", если авторизационный код
/// обменивается на маркер доступа;
Parameter GRANTTYPE = "authorization_code";

/// Должно иметь значение “refresh_token”, поскольку маркер обновления
/// обменивается на маркер доступа;
Parameter GRANTTYPEREFRESH = "refresh_token";

/// SSL конфигурация. 
/// Генерация:
/// w $System.Status.GetErrorText(##class(isc.util.ESIAUtils).createSSLConfig())
Parameter SSLCONFIG = "ESIAOAuth";

/// Получить ссылку редиректа пользователя для того чтобы он дал доступ.
/// w ##class(isc.esia.configuration.Abstract).getLoginURL()
ClassMethod getLoginURL() As %String
{
	set params("client_id") = ..#CLIENTID
	set params("redirect_uri") = ..getLoginRedirectURL()
	set params("scope") = ..#SCOPE
	set params("response_type") = ..#RESPONSETYPE
	set params("state") = ..getState()
	set params("timestamp") = ..getTimestamp()
	set params("access_type") = ..#ACCESSTYPE
	set params("client_secret") = ..getSecret(params("scope"), params("timestamp"), params("client_id"), params("state"))
	
	set url = "https://" _ ..#SERVER _ "/aas/oauth2/ac?"
	
	set key = ""
	for {
		set key=$order(params(key), 1, value) 
		quit:key="" 
		set url = url _ key _ "=" _ $zcvt(value, "O", "URL")  _ "&" //##class(isc.util.SamlUtils).urlEncodePlus(value)
	}
	
	set url = $e(url, 1, *-1)
	quit url
}

/// Подпись запроса в формате PKCS#7 detached signature в кодировке UTF-8 
/// от значений четырех параметров HTTP–запроса: scope, timestamp, clientId, state (без
/// разделителей). <client_secret> должен быть закодирован в формате base64 url safe.
/// Используемый для проверки подписи сертификат должен быть предварительно
/// зарегистрирован в ЕСИА и привязан к учетной записи системы-клиента в ЕСИА. ЕСИА
/// поддерживает сертификаты в формате X.509. ЕСИА поддерживает алгоритмы
/// формирования электронной подписи RSA с длиной ключа 2048 и алгоритмом
/// криптографического хэширования SHA-256, а также алгоритм электронной подписи
/// ГОСТ Р 34.10-2001 и алгоритм криптографического хэширования ГОСТ Р 34.11-94
/// w ##class(isc.esia.configuration.Abstract).getSecret("fullname","2018.02.09 05:35:13 +0000")
ClassMethod getSecret(scope, timestamp, clientId = {..#CLIENTID}, state = {..getState()}) As %String
{
	set text = scope _ timestamp _ clientId _ state
	set text = $zcvt(text, "O", "UTF8")
	
	$$$TOE(sc,  $classmethod(##class(isc.esia.Settings).getSetting("signer"), "sign", text, .signedText))
	set signedText = ##class(isc.util.ESIAUtils).base64URLEncode(signedText)

	quit signedText
}

/// Протокол + Сервер + Приложение 
/// w ##class(isc.esia.configuration.Abstract).getRedirectURL()
ClassMethod getBaseRedirectURL() As %String
{
	#dim %request As %CSP.Request
	#dim %session As %CSP.Session
	if $isobject($g(%request)) {
		set protocal = "http" _ $case(%request.Secure, $$$YES: "s", :"")
		set host = %request.CgiEnvs("HTTP_HOST")
		set app = %session.Application
	} else {
		set protocal = "http"
		set host = "localhost"
		set app = "/esia/"
	}
	
	quit protocal _ "://" _ host _ app
}

/// Ccылка, по которой должен быть направлен пользователь после того, как даст разрешение на доступ к ресурсу.
/// Путь '/loginResponse' текущего брокера
/// w ##class(isc.esia.configuration.Abstract).getLoginRedirectURL()
ClassMethod getLoginRedirectURL() As %String [ CodeMode = expression ]
{
..getBaseRedirectURL() _ "loginResponse"
}

/// Ccылка, по которой должен быть направлен пользователь после того, как даст разрешение на доступ к ресурсу.
/// Путь '/logoutResponse' текущего брокера
/// TODO. Не работает. Не перенаправляет обратно. В.6.5 Стр. 162
/// В ЕСИА для интегрированной системы может быть определен параметр system.siteUrl,
/// содержащий URL-адрес системы, на который будет возвращен пользователь после логаута.
/// Redirect_url должен быть подстрокой system.siteUrl.
/// w ##class(isc.esia.configuration.Abstract).getLogoutRedirectURL()
ClassMethod getLogoutRedirectURL() As %String [ CodeMode = expression ]
{
..getBaseRedirectURL() _ "logoutResponse"
}

/// Набор случайных символов, имеющий вид 128-битного идентификатора запроса,
/// генерируется по стандарту UUID;
ClassMethod getState() As %String
{
	quit $zcvt($System.Util.CreateGUID(), "l")
}

/// Время запроса авторизационного кода в формате yyyy.MM.dd HH:mm:ss Z
/// (например, 2013.01.25 14:36:11 +0400), необходимое для фиксации начала временного
/// промежутка, в течение которого будет валиден запрос с данным идентификатом
/// w ##class(isc.esia.configuration.Abstract).getTimestamp()
ClassMethod getTimestamp() As %String
{
	quit $system.SQL.TOCHAR($p($ZTIMESTAMP,"."),"yyyy.MM.dd HH24:mi:ss") _" +0000"
}

/// Обменять авторизационный код на токен доступа.
/// do ##class(isc.esia.configuration.Test).sendTokenRequest()
ClassMethod sendTokenRequest(code As %String, Output response) As %Status
{
	set response = ""
	#dim sc As %Status = $$$OK
	
	set timestamp = ..getTimestamp()
	set state = ..getState()
	
	set req = ..getRequest()
	do req.InsertFormData("client_id", ..#CLIENTID)
	do req.InsertFormData("code", code)
	do req.InsertFormData("grant_type", ..#GRANTTYPE)
	do req.InsertFormData("client_secret",  ..getSecret(..#SCOPE, timestamp, ..#CLIENTID, state))
	do req.InsertFormData("state", state)
	do req.InsertFormData("redirect_uri", ..getLoginRedirectURL())
	do req.InsertFormData("scope", ..#SCOPE)
	do req.InsertFormData("timestamp", timestamp)
	do req.InsertFormData("token_type", ..#TOKENTYPE)
	
	set sc = ..sendRequest("POST", "/aas/oauth2/te", .response, req)
			
	quit sc
}

/// Обменять авторизационный код на токен доступа.
/// do ##class(isc.esia.configuration.Test).sendRefreshRequest()
ClassMethod sendRefreshRequest(tokenObj As isc.esia.data.Token) As %Status
{
	set response = ""
	#dim sc As %Status = $$$OK
	
	set timestamp = ..getTimestamp()
	set state = ..getState()
	
	set req = ..getRequest()
	do req.InsertFormData("client_id", ..#CLIENTID)
	do req.InsertFormData("refresh_token", tokenObj.refreshToken)
	do req.InsertFormData("grant_type", ..#GRANTTYPEREFRESH)
	do req.InsertFormData("client_secret",  ..getSecret(..#SCOPE, timestamp, ..#CLIENTID, state))
	do req.InsertFormData("state", state)
	do req.InsertFormData("redirect_uri", ..getLoginURL())
	do req.InsertFormData("scope", ..#SCOPE)
	do req.InsertFormData("timestamp", timestamp)
	do req.InsertFormData("token_type", ..#TOKENTYPE)
	
	set sc = ..sendRequest("POST", "/aas/oauth2/te", .response, req, 2)
	
	do tokenObj.updateFromJSON(response)
			
	quit sc
}

/// Отправить запрос на получение базовых данных из ЕСИА
/// do ##class(isc.esia.configuration.Test).sendDataRequest()
ClassMethod sendDataRequest(token As %String, oid As %String, Output response) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ..sendRequest("GET", "/rs/prns/" _ oid _ "?embed=(organizations,contacts.elements)", .response, token)
	quit sc
}

/// Получить базовый объект запроса
/// token (опционально) - токен выданный данному пользователю
ClassMethod getRequest(token As %String = "") As %Net.HttpRequest
{
	set req = ##class(%Net.HttpRequest).%New()
	set req.SSLConfiguration = "GitHub"
	set req.Server = ..#SERVER
	set req.Https = $$$YES
	set:token'="" req.Authorization =  "Bearer " _ token
	quit req
}

/// Отправить запрос на сервер ЕСИА
/// method - HTTP метод
/// location - куда отправлять запрос на сервере ЕСИА
/// response - тело ответа в UTF8
/// request (опционально) - объект запроса, либо токен доступа. 
/// test (опционально) - тестирование 0 - без тестирования, 1 - вывести запрос на устройство, 2 - вывести ответ на устройство
ClassMethod sendRequest(method As %String(VALUELIST="GET,POST"), location As %String, Output response As %String, request As %Net.HttpRequest = "", test As %Integer(MINVAL=0,MAXVAL=2) = 0) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ""
	set:'$isobject(request) request = ..getRequest($g(request))
	
	set sc = request.Send(method, location, test)
	
	if (test '= 1) {
		if (request.HttpResponse.StatusCode = 200) {
			set response = request.HttpResponse.Data.Read($$$MaxStringLength)
			set response = $zcvt(response, "I", "UTF8")
		} else {
			set sc = $$$ADDSC(sc, $$$ERROR($$$GeneralError, $$$FormatText("При выполнении запроса '%1' получили статус %2. Тело ответа: %3", location, request.HttpResponse.StatusCode, request.HttpResponse.Data.Read($$$MaxStringLength))))
		}
	}
	quit sc
}

/// Получить ссылку редиректа для выхода пользователя
/// w ##class(isc.esia.configuration.Abstract).getLogoutURL()
ClassMethod getLogoutURL() As %String
{
	set params("client_id") = ..#CLIENTID
	set params("redirect_url") = ..getLogoutRedirectURL()
		
	set url = "https://" _ ..#SERVER _ "/idp/ext/Logout?"
	
	set key = ""
	for {
		set key=$order(params(key), 1, value) 
		quit:key="" 
		set url = url _ key _ "=" _ $zcvt(value, "O", "URL")  _ "&"
	}
	
	set url = $e(url, 1, *-1)
	quit url
}

}


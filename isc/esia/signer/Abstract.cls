Class isc.esia.signer.Abstract
{

/// Имя конфигурации (опционально)
Parameter NAME;

/// Подписать запрос.
ClassMethod sign(text As %String, Output out As %String) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

/// Проверить подпись
ClassMethod verify(text As %String, signature As %String) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

}


Class isc.esia.data.Token Extends (%Persistent, isc.esia.data.Abstract)
{

/// Время в секундах, которое мы отнимаем от настоящего времени истечения срока действия токена
Parameter EXPIRELIMIT = 60;

/// Маркер доступа для данного ресурса;
Property accessToken As %String(CAPTION = "access_token", MAXLEN = "");

/// Маркер обновления для данного ресурса.
Property refreshToken As %String(CAPTION = "refresh_token", MAXLEN = "");

/// Время, после которого истекает срок действия маркера (обновления)
Property expiresOn As %TimeStamp(CAPTION = "expires_in");

/// GUID
Property state As %String(CAPTION = "state");

Method onFromJSON(jsonObj As %DynamicObject)
{
	set expiresOn = $system.SQL.DATEADD("s", ..expiresOn - ..#EXPIRELIMIT, $ztimestamp)
	set ..expiresOn = expiresOn
}

Storage Default
{
<Data name="TokenDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>accessToken</Value>
</Value>
<Value name="3">
<Value>refreshToken</Value>
</Value>
<Value name="4">
<Value>expireTS</Value>
</Value>
<Value name="5">
<Value>state</Value>
</Value>
<Value name="6">
<Value>expiresOn</Value>
</Value>
</Data>
<DataLocation>^isc.esia.data.TokenD</DataLocation>
<DefaultData>TokenDefaultData</DefaultData>
<IdLocation>^isc.esia.data.TokenD</IdLocation>
<IndexLocation>^isc.esia.data.TokenI</IndexLocation>
<StreamLocation>^isc.esia.data.TokenS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}


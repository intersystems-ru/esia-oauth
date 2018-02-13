Class isc.esia.data.Contact Extends (%SerialObject, isc.esia.data.Abstract)
{

/// Тип контакта
/// MBT – мобильный телефон
/// PHN – домашний телефон
/// EML – электронная почта
/// CEM – служебная электронная почта
Property type As %String;

/// Сведения о «подтвержденности» контактов, может иметь значения:
/// NOT_VERIFIED – не подтвержден;
/// VERIFIED – подтвержден.
/// В настоящее время статус "VERIFIED" может быть только у мобильного телефона ("MBT") и адреса электронной почты ("EML").
Property verified As %Boolean(CAPTION = "vrfStu");

/// Значение контакта;
Property value As %String;

/// Указывается в случае, если контакт находится в процессе подтверждения. 
Property onVerification As %Boolean(CAPTION = "vrfValStu") [ InitialExpression = 0 ];

Property verifyingValue As %String;

Method onFromJSON(jsonObj As %DynamicObject)
{
	set:..onVerification="VERIFYING" ..onVerification = $$$YES
	set ..verified = $case(..verified, "VERIFIED" : $$$YES, :$$$NO)
}

Storage Default
{
<Data name="ContactState">
<Value name="1">
<Value>type</Value>
</Value>
<Value name="2">
<Value>verified</Value>
</Value>
<Value name="3">
<Value>value</Value>
</Value>
<Value name="4">
<Value>onVerification</Value>
</Value>
<Value name="5">
<Value>verifyingValue</Value>
</Value>
</Data>
<State>ContactState</State>
<StreamLocation>^isc.esia.data.ContactS</StreamLocation>
<Type>%Library.CacheSerialState</Type>
}

}


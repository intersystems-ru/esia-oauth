/// Персональные данные пользователя
Class isc.esia.data.Person Extends (%Persistent, isc.esia.data.Abstract)
{

/// Уникальный идентификатор.
Property oid As %String;

Index oidIndex On oid [ Unique ];

/// Ссылка на токен связанный с этим пользователем.
Property token As isc.esia.data.Token;

/// Идентификатор текущего документа пользователя.
Property rIdDoc As %String;

/// Имя
Property firstName As %String;

/// Фамилия
Property lastName As %String;

/// Отчество
Property middleName As %String;

/// Дата рождения. 
/// Пишут что это unixtime но возвращают dd.mm.yyyy.
Property birthDate As %Date;

/// Место рождения пользователя;
Property birthPlace As %String(MAXLEN = "");

/// Пол
Property gender As %String;

/// Ттип учетной записи (подтверждена ("true") / не подтверждена ("false"));
Property trusted As %Boolean;

/// Гражданство (идентификатор страны гражданства);
Property citizenship As %String;

/// СНИЛС
Property snils As %String;

/// ИНН;
Property inn As %String;

/// Дата последнего изменения учетной записи пользователя
Property updatedOn As %TimeStamp;

/// Процесс проверки данных (true/false);
Property verifying As %String;

/// Статус УЗ (Registered – зарегистрирована/Deleted – удалена)
Property status As %String;

/// Контакты (телефон, почта) пользователя.
Property contacts As array Of isc.esia.data.Contact(SQLPROJECTION = "table/column");

/// Перечень организаций, сотрудником которых
/// является физическое лицо с данным {oid} (в виде
/// ссылок на ресурс c указанием {oid}, содержащий
/// данные о каждой организации)
Property organizations As list Of %String(MAXLEN = "", SQLPROJECTION = "table/column", STORAGEDEFAULT = "array");

/// Список групп пользователя
Property groups As list Of %String;

Method onBeforeFromJSON(jsonObj As %DynamicObject) As %Boolean
{
	// TODO
	quit $$$YES
	set newUpdatenOn = $zdt($zdth(jsonObj.updatedOn, -2), 3, 1)
	quit:newUpdatenOn=..updatedOn $$$NO
	quit:$system.SQL.DATEDIFF("s", ..updatedOn, newUpdatenOn)<0 $$$NO
	quit $$$YES
}

Method onFromJSON(jsonObj As %DynamicObject)
{
	set ..birthDate = $zdh($tr(..birthDate,".","/"), 4,,,,,,,, 1)
	set ..updatedOn = $zdt($zdth(..updatedOn, -2), 3, 1)
	
	if jsonObj.%IsDefined("contacts") {
		/// TODO clear?
		set iterator = jsonObj.contacts.elements.%GetIterator()
		while iterator.%GetNext(.key, .value) {
			#dim contact,oldContact As isc.esia.data.Contact
			set contact = ##class(isc.esia.data.Contact).fromJSON(value)
			set type = contact.type
			set oldContact = ..contacts.GetAt(type)
			if (oldContact'=$$$NULLOREF) {
				do contact.%SerializeObject(.contactSerialized)
				do oldContact.%SerializeObject(.oldContactSerialized)
				continue:contactSerialized=oldContactSerialized
			}
			do ..contacts.SetAt(contact, type)
		}
	}
	
	if jsonObj.%IsDefined("organizations") {
		set iterator = jsonObj.organizations.elements.%GetIterator()
		do ..organizations.Clear() // TODO compare
		while iterator.%GetNext(.key, .value) {
			do ..organizations.Insert(value.oid)
		}
	}
}

Method setGroups(jsonObj As %DynamicObject)
{
	if jsonObj.%IsDefined("elements") {
		/// TODO clear?
		set iterator = jsonObj.elements.%GetIterator()
		while iterator.%GetNext(.key, .value) {
			do ..groups.Insert($piece(value,"grps/",*))
	}
}
}

Method setSession()
{
	if $isObject($g(%session)) { 
		///set %session.Data("SessionIndex") = obj.SessionIndex
		set %session.Data("NameID") = ..oid
        set %session.Data("lastName") = ..lastName
        set %session.Data("firstName") = ..firstName
        set %session.Data("middleName") = ..middleName
        set %session.Data("birthDate") = ..birthDate
        set %session.Data("snils") = ..snils
        
        #dim email As Contact = ..contacts.GetAt("EML")        
        set:$isObject(email) %session.Data("email") = email.value

		set groupList = ""
		for i=1:1:..groups.Count() {
			set groupList = groupList _ $lb(..groups.GetAt(i))
		} 
		// TODO
        //set %session.Data("ogrn") = ..
        set %session.Data("groups") = $lts(groupList)
        set %session.Data("fullName") = %session.Data("lastName") _ " " _ %session.Data("firstName") _ " " _ %session.Data("middleName")
	}
}

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>oid</Value>
</Value>
<Value name="3">
<Value>token</Value>
</Value>
<Value name="4">
<Value>rIdDoc</Value>
</Value>
<Value name="5">
<Value>firstName</Value>
</Value>
<Value name="6">
<Value>lastName</Value>
</Value>
<Value name="7">
<Value>middleName</Value>
</Value>
<Value name="8">
<Value>birthDate</Value>
</Value>
<Value name="9">
<Value>birthPlace</Value>
</Value>
<Value name="10">
<Value>gender</Value>
</Value>
<Value name="11">
<Value>trusted</Value>
</Value>
<Value name="12">
<Value>citizenship</Value>
</Value>
<Value name="13">
<Value>snils</Value>
</Value>
<Value name="14">
<Value>inn</Value>
</Value>
<Value name="15">
<Value>updatedOn</Value>
</Value>
<Value name="16">
<Value>verifying</Value>
</Value>
<Value name="17">
<Value>status</Value>
</Value>
<Value name="18">
<Value>groups</Value>
</Value>
</Data>
<Data name="contacts">
<Attribute>contacts</Attribute>
<Structure>subnode</Structure>
<Subscript>"contacts"</Subscript>
</Data>
<Data name="organizations">
<Attribute>organizations</Attribute>
<Structure>subnode</Structure>
<Subscript>"organizations"</Subscript>
</Data>
<DataLocation>^isc.esia.data.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^isc.esia.data.PersonD</IdLocation>
<IndexLocation>^isc.esia.data.PersonI</IndexLocation>
<StreamLocation>^isc.esia.data.PersonS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}


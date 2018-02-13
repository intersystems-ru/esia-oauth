Include %syPrompt

Class isc.esia.Settings
{

Parameter GLVN = "^ESIA";

Parameter BASECONFIG = "isc.esia.configuration.Abstract";

Parameter BASESIGNER = "isc.esia.signer.Abstract";

/// Получить настойку
/// config - имя класса реализующего интерфейс isc.esia.Configuration.Abstract
/// signer - имя класса реализующего интерфейс isc.esia.Signer.Abstract
/// write ##class(isc.esia.Settings).getSetting("config")
ClassMethod getSetting(name As %String) As %String [ CodeMode = expression ]
{
$get(@..#GLVN@($zcvt(name, "l")))
}

/// Установить настройку
/// write ##class(isc.esia.Settings).setSetting("config", "isc.esia.configuration.Test")
/// write ##class(isc.esia.Settings).setSetting("signer", "isc.esia.signer.OpenSSL")
ClassMethod setSetting(name As %String = "", value As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	
	if name = "config" {
		if '##class(%Dictionary.ClassDefinition).%ExistsId(value) {
			set sc = $$$ERROR($$$GeneralError, $$$FormatText("Класс '%1' не существует", value))
		}
		quit:$$$ISERR(sc) sc
		
		if $classmethod(value, "%Extends", ..#BASECONFIG)=$$$NO {
			set sc = $$$ERROR($$$GeneralError, $$$FormatText("Класс '%1' не является потомком %2", value, ..#BASECONFIG))
		}	
	} elseif name = "signer" {
		if '##class(%Dictionary.ClassDefinition).%ExistsId(value) {
			set sc = $$$ERROR($$$GeneralError, $$$FormatText("Класс '%1' не существует", value))
		}
		quit:$$$ISERR(sc) sc
		
		if $classmethod(value, "%Extends", ..#BASESIGNER)=$$$NO {
			set sc = $$$ERROR($$$GeneralError, $$$FormatText("Класс '%1' не является потомком %2", value, ..#BASESIGNER))
		}
	} else {
		set sc = $$$ERROR($$$GeneralError, $$$FormatText("Свойство '%1' не существует", name))
	}
	
	set:$$$ISOK(sc) @..#GLVN@($zcvt(name, "l")) = value
	return sc
}

/// do ##class(isc.esia.Settings).subclassQueryFunc().%Display()
Query subclassQuery(base = {..#BASECONFIG}) As %SQLQuery
{
SELECT 
  c.Name || ': ' ||  p._Default 
FROM %Dictionary.ClassDefinitionQuery_SubclassOf(:base) c
JOIN %Dictionary.CompiledParameter p ON c.Name = p.parent AND p.Name = 'NAME'
}

/// Интерактивная установка конфигурации и криптопровайдера.
/// do ##class(isc.esia.Settings).install()
ClassMethod install() As %Status
{
	#dim sc,sc1 As %Status = $$$OK
	
	do ##class(%Prompt).GetArray("Выберите конфигурацию", .choice, $lb($classname() _ ":subclassQuery", ..#BASECONFIG),,,,$$$InitialDisplayMask)
	set config = $piece(choice, ":")
	
	set sc = ..setSetting("config", config)
	write !
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	
	kill choice
	
	do ##class(%Prompt).GetArray("Выберите криптопровайдер", .choice, $lb($classname() _ ":subclassQuery", ..#BASESIGNER),,,,$$$InitialDisplayMask)
	set signer = $piece(choice, ":")
	
	set sc1 = ..setSetting("signer", signer)
	write:$$$ISERR(sc1) $System.Status.GetErrorText(sc1)
		
	quit $$$ADDSC(sc, sc1)
}

}


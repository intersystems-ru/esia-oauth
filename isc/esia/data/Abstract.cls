Class isc.esia.data.Abstract [ Abstract ]
{

ClassMethod fromJSON(json As %String) As %RegisteredObject
{
	set obj = ..%New()
	do obj.updateFromJSON(json)
    quit obj
}

/// Обновление существующего объекта.
/// json - строка с json либо динамический объект
Method updateFromJSON(json As %String) [ CodeMode = objectgenerator ]
{
	
	do %code.WriteLine(" set jsonObj = $case($isObject(json), $$$YES:json, :{}.%FromJSON(json))")
	do %code.WriteLine(" if ..onBeforeFromJSON(jsonObj) {")
	for i = 1:1:%compiledclass.Properties.Count() {
		#dim prop As %Dictionary.CompiledProperty
        set prop = %compiledclass.Properties.GetAt(i)
        set jsonName = prop.Parameters.GetAt("CAPTION")
        set:jsonName="" jsonName = prop.Name
        set jsonName = $$$quote(jsonName)
        if prop.Internal || prop.Calculated || prop.ReadOnly || prop.Private || prop.Identity || prop.MultiDimensional || (prop.Collection'="") continue
		
		do %code.WriteLine("	set:jsonObj.%IsDefined(" _ jsonName _") .." _ prop.Name _ " = jsonObj." _ jsonName)
    }
    do %code.WriteLine(" 	do ..onFromJSON(jsonObj)")
    do %code.WriteLine(" }")
    quit $$$OK
}

/// Коллбэк вызываемый после обновления объекта из json
Method onFromJSON(jsonObj As %DynamicObject)
{
}

/// Обновление объекта происходит только есть этот метод возвращает $$$YES
Method onBeforeFromJSON(jsonObj As %DynamicObject) As %Boolean
{
	quit $$$YES
}

}


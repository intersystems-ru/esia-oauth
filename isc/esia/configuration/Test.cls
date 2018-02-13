Class isc.esia.configuration.Test Extends isc.esia.configuration.Abstract
{

Parameter NAME = "Тестовая конфигурация ЕСИА";

/// Идентификатор системы-клиента (мнемоника системы в ЕСИА)
Parameter CLIENTID;

/// Сервер ЕСИА
Parameter SERVER = "esia-portal1.test.gosuslugi.ru";

/// Область доступа, т.е. запрашиваемые права; например, если система-клиент
/// запрашивает доступ к сведениям о сотрудниках организации, то scope должна иметь
/// значение http://esia.gosuslugi.ru/org_emps (с необходимыми параметрами); если
/// запрашивается scope id_doc61 (данные о пользователе), то не нужно в качестве параметра
/// указывать oid этого пользователя;
Parameter SCOPE = "fullname birthdate gender snils email mobile contacts usr_org";

}


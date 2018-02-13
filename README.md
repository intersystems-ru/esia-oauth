# esia-oauth
Аутентификация OAuth для ЕСИА. ESIA OAuth authentiaction

## Установка

1. Загрузите код или [готовую сборку](https://github.com/intersystems-ru/esia-oauth/releases)
2. Скомпилируйте классы командой: `do $system.OBJ.Compile("isc.esia.*,isc.utils.ESIAUtils")`
3. Создайте SSL конфигурацию: `write $System.Status.GetErrorText(##class(isc.util.ESIAUtils).createSSLConfig())`
4. Создайте веб приложение: `write $System.Status.GetErrorText(##class(isc.util.ESIAUtils).сreateWebApp())`

## Настройка

1. Отнаследуйтесь от `isc.esia.configuration.Test` и преопределите параметр `CLIENTID`.
2. Отнаследуйтесь от `isc.esia.signer.OpenSSL` и преопределите методы `getKey` и `getCertificate`. Ключ должен быть без пароля.
3. Выполните: `do ##class(isc.esia.Settings).install()` и выберите созданные вами классы.

## Использование

1. Для входа откройте: `http://localhost:57772/esia/login`
2. Для выхода откройте: `http://localhost:57772/esia/logout`

## Разработка

Разработка в [Cache-Tort-Git UDL](https://github.com/MakarovS96/cache-tort-git).

# Установка:
- вставить интернет карту и запустить эту команду в терминале `wget -f https://raw.githubusercontent.com/asvdvl/asvlibs/master/installer.lua /tmp/installer.lua ; /tmp/installer.lua`

# asvlibs
Этот репозиторий содержит разного рода библиотеки для разных задач. Все библиотеки загружаются и автоматически скачиваются(при наличии интернет карты и отсутствие конечного файла) через init.lua, поэтому, для использования любой библиотеки установить нужно только init.lua.

## utils
Библиотека содержащяя функции разного назначения.
Требует Lua 5.3
- reverseTable(inputTable:table) -- "Переворачивает" таблицу.
  - Пример:
  - reverseTable({1, 2, "3", 4.1, 5}) --return: {5, 4.1, "3", 2, 1}
  
- concatinateBytes(bytesTable:table) -- Соединяет группы из байт в одно число. 
  - Пример:
  - concatinateBytes({43, 215}) --return: 11223
  
- concatinateStrings(stringsTable:table) --Соединяет группы из строк в одну.
  - Пример:
  - concatinateStrings({"te", "st", " ", "strin", "g"}) --return: "test string"

- splitIntoBytes(number: integer, length:integer(не обязательно)) -- Разделяет число на группы по 1 байту.
  - Пример:
  - splitIntoBytes(11223) --return: {43, 215}

- splitByChunk(string:string, length:integer) -- Разбивает строку на строки с указанной длинной
  - Пример:
  - splitByChunk("test string") --return:{"te", "st", " s", "tr", "in", "g"}

- correctTableStructure(inputTable:table, templateTable:table) -- Исправляет несоответствия полей во входной таблице в соответствие с таблицой-примером.(Не работает с нумерованными таблицами!)
  - Пример:
  - correctTableStructure({a = "apple", c = "code", d = "dimention"}, {a = "Sapple", b = "Sbite", c = "code"}) --return:{a = "apple", b = "Sbite", c = "code"}, true(были ли изменения в таблице)

- confirmAction(message(не обязательно), yes(не обязательно)) -- Запрос у пользователя о подтверждении действия. 
  - Пример:
  - confirmAction("test question") --return: true/false(Зависит от выбора пользователя)

## dbg
Библиотека для интерактивной отладки скриптов. (в разработке)
использование: \
`local dbg = require("asv").dbg`\
`...`\
`dbg()`\
`...`


## settings
Библиотека для сохранения и восстановления "настроек".
Использование: 
- Подключение: `local set = require("asv").settings`
- Получение настроек из файла: `set.getSettings(<имя файла>, [<значение по умолчанию>], [<не исправлять структуру>]):успех, данные`
  - `успех` (boolean): 
    - false 
      - не удалось прочитать
      - `данные` - причина неудачи
    - true 
      - успешно прочитано
      - `данные` - прочитанные данные
- Сохранение настроек в файл: `set.setSettings(<имя файла>, <значение>): успех, причина`
### Параметры:
`getSettings`
- `<имя файла>` (string): Имя или путь к файлу. Если переданная строка не начинается с `/` то это считается относительным путем и файл по умолчанию сохраняется в `/etc/settings/` иначе, по указанному пути. 
- `<значение по умолчанию>` (boolean, number, string, table): Если файла не существует то он создается и записывается это значение. 
- `<не исправлять структуру>` (boolean): (__Исправление рботает только для ассоциативных массивов__) Необходим параметр `<значение по умолчанию>` как шаблон. Если `true` - не пытатся исправлять значение.
`setSettings`
- `<значение>` (nil, boolean, number, string, table): Записываемое значение.

## time
Библиотека получения __реального__ времени хост машины.
Использование: 
- Подключение: `local time = require("asv").time`
- `getRaw()` выдает значение как оно есть(время в UNIX формате, в милисекундах)
- `getUNIX(timeZone)` UNIX секунды
- `getBySpecificFormat(format, timeZone)` отображает время в вашем формате. 
- `getTime(timeZone)` Отображение времени в стандартном формате.
- `getDate(timeZone)` Отображение даты в стандартном формате.
- `getDateTime(timeZone)` Отображение даты и времени в стандартном формате.
### Параметры
- timeZone - смещение в часах от gmt
- format - [с.м. форматы для os.date](http://www.lua.org/manual/5.3/manual.html#pdf-os.date)
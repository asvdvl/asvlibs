# asvlibs
Этот репозиторий содержит разного рода библиотеки для разных задач.

## asvutils.lua
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

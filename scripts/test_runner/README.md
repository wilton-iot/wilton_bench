# servers_benchmarks
Скрипты для запуска нагрузки и сбора статистики по состоянию системы.

Запускаемые программы:
- free
- iostat
- mpstat
- iostat
- top
- wrk
- тестируемый сервер

**Обратите внимание**: wrk подключен как подмодуль, скрипт *servers_test.sh* запускает *wrk* как *"./wrk/wrk %args%"* 

Для получения информации об использовании скриптов необходимо выполнить следующие команды:
```
	./server_test.sh --help
```


Основной скрипт servers_test.sh запускает сервер и программы мониторинга, собирающие данные с интервалом в 1 секунду. Потом запускает wrk с определенными параметрами.
Параметры для wrk указываются в текстовом файле, по аналогии с wrk_test_params.txt

Команда запуска:
```
	./server_test.sh [-test] -- server_directory server_name args store_directory server_url wrk_parameters_file
```

-test - Флаг, который остановит выполнение скрипта после попытки запустить сервер.
         У пользователя будет возможность проверить запустился ли сервер.
         Если сервер не запустился - введите q для выхода из скрипта.
         Если сервер запустился - любой ввод отличный от q продолжит выполнение скрипта.

Директория запускаемой программы и ее имя указываются отдельно, в дальнейшем имя программы используется для автоматического разбора данных от top.


Примеры вызова servers_test.sh:
```
	./servers_test.sh -- "" node "./node_server/server.js" node_test_1 http://127.0.0.1:8080/index.html wrk_test_params.txt
	
	./servers_test.sh -- ../main/wilton/build/wilton_201712220/bin/ wilton ./js_wilton_server/index.js js_wilton_test_4_thr_1 http://127.0.0.1:8080/js_wilton_server/views/hi wrk_test_params.txt
	
	./servers_test.sh -- ./golang_server/ golang_server "proxy" golang_test_1 http://127.0.0.1:8080/index.html wrk_test_params.txt
	
	./servers_test.sh -- ./wilton_server/ test_server 4 wilton_server_test_1 http://127.0.0.1:8080/index.html wrk_test_params.txt
```


Для автоматического запуска скриптов можно использовать **./run_load_tests.sh**



### Обработка файлов статистики.

Если необходимо построить графики данных, удобно использовать скрипты из каталога **../test_data_handler**.
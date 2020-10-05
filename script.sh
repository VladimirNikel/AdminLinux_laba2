#!/usr/bin/env bash
#**************************************************
#Автор: Ниемисто Владимир [Nikel], М3О-117М-20
#Название программы: Анализатор log-файлов 3000
#Описание: Эта вундер-вафля умеет:
#	1. Принимает на вход путь до log-файла
#	2. Если путь не был указана - завершаем работу с кодом 10
#	3. Если переданный параметр - не файл, то завершаем работу кодом 20
#	4. Анализировать log-файл (если это log-файл)
#**************************************************

request=$(ps aux | grep $0 | wc -l)
echo "ответ: "$request
if [[ $request -gt 3 ]]				#	gt - больше			проверка на мультизапуск	(3 - эмпирически выведенное значение)
then
	#если больше 3 - значит запущена еще одна команда
	echo "Запущена еще одна копия данного скрипта - я завершаю работу."
	exit 40
else	#проверка пройдена - запущена всего одна копия данного скрипта, значит, продолжаем работу

	if [[ $1 != "" ]]				#проверка на наличие первого параметра
	then
		#код, который выполняется, ежели у нас есть первый параметр
		if [[ -f $1 ]]				#проверка на то, файлик это или нет
		then
			#echo "Файлик существует. Ты молодец"
			if [[ -s $1 ]]			#проверка на пустоту файла
			then
				echo "Файлик не пуст - всё хорошо, работаем дальше"
			else
				#echo "Файлик пуст - орём, материмся, бегаем!"
				exit 30
			fi
		else
			#echo "Ты меня обманул: это не файлик!"
			exit 20
		fi
	else
		#echo "Параметр не был передан - лежим в слезах с ошибкой 10"
		exit 10
	fi

fi
exit 0 
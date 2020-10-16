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

set -eo pipefail
main_function(){
	temp=/tmp/log_analyser_dates.tmp
	current_data=$(date "+%d/%b/%Y:%T")
	current_data_sec=$(date +%s)
	my_str="ЗАПИСИ ОБРАБОТАНЫ "$current_data

	#Выводим текущую дату
	echo "Текущая дата: $current_data"

	# Проверяем, запускался ли скрипт до этого момента. Если да, то получаем дату последнего запуска
	if [ -f $temp ]
	then
		last_data_sec=$(cat $temp | tail -n 1)
		last_data=$(date --date=@$last_data_sec "+%d/%b/%Y:%T")
		echo "Прошлая дата анализа: $last_data"
	fi

	# Считаем количество новых записей в логе
	echo "Начат подсчет новых записей"
	#date "+%s" --date="$(tail -n1 nginx_logs | awk -F "[" {'print $2'} | awk {'print $1'} | sed "s/\//\ /g" | sed "s/:/ /" )"
	new_records_count=$( tac $1 | awk '{  if ( $1=="ЗАПИСИ" && $2=="ОБРАБОТАНЫ" ) exit 0 ; else print }' | wc -l || true )
	#echo "$(tac $1 | awk '{ if ( $1=="ЗАПИСИ" && $2=="ОБРАБОТАНЫ" ) { exit 0 } else { print } }' | wc -l)"
	
	if [ $new_records_count -le 0 ]
	then
		echo "Нет новых записей в $1 с $last_data"
		echo $current_data_sec >> $temp
		exit 0
	fi
	#let new_records_count--
	echo "Количество новых записей в log-файле: $new_records_count"
	echo $my_str >> $1

	start_time_rande=$(cat $1 | head --line -1 | cut -d ' ' -f 4 | tail -n $new_records_count | sort -n | head -n1 | awk -F"[" '{print $2}' || true)
	finish_time_rande=$(cat $1 | head --line -1 | cut -d ' ' -f 4 | tail -n $new_records_count | sort -nr | head -n1 | awk -F"[" '{print $2}' || true)
	echo -e "Обрабатываемый диапазон: $start_time_rande - $finish_time_rande"

	echo -e "\nТоп-15 IP-адресов, с которых посещался сайт\n"
	cat $1 |
	head --line -1 |
	tail -n $new_records_count |
	cut -d ' ' -f 1 |
	sort |
	uniq -c |
	sort -nr |
	head -n 15 |
	awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t\t",$2; }' || true

	echo -e "\nТоп-15 ресурсов сайта, которые запрашивались клиентами\n"
	cat $1 |
	head --line -1 |
	tail -n $new_records_count |
	cut -d ' ' -f 7 |
	sort |
	uniq -c |
	sort -nr |
	head -n 15 |
	awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t",$2; }' || true

	echo -e "\nСписок всех кодов возврата\n"
	cat $1 |
	head --line -1 |
	tail -n $new_records_count |
	cut -d ' ' -f 9 |
	sort |
	sed 's/[^0-9]*//g' |
	awk -F '=' '$1 > 100 {print $1}' |
	uniq -c  |
	head -n 15 |
	awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t\t\t",$2; }'|| true

	echo -e "\nСписок кодов возврата 4xx и 5xx (только ошибки)\n"
	cat $1 |
	head --line -1 |
	tail -n $new_records_count |
	cut -d ' ' -f 9 |
	sort |
	sed 's/[^0-9]*//g' |
	awk -F '=' '$1 > 400 {print $1}' |
	uniq -c  |
	head -n 15 |
	awk '{ t = $1; $1 = $2; $2 = t; print $1,"\t\t\t",$2; }'|| true

	# Записываем дату последнего запуска скрипта
	echo $current_data_sec >> $temp
}


request=$(ps aux | grep $0 | wc -l)
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
				#echo "Файлик не пуст - всё хорошо, работаем дальше"
				main_function $1
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
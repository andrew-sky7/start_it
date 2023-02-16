/* Шукаємо пасажирів, у яких ID дорівнює: або 2, або 3, або 4, або 10*/
SELECT id, Surname, name, date_of_birth 'date of birth', id*2 as column1
    FROM passenger p
	WHERE id IN (2,3,4,10)
GO

/* Обмеження на виведення рядків*/
SELECT TOP 10 *
    FROM pass_in_trip
ORDER BY passenger_id ASC, date DESC, trip_id ASC

  /* Визначити, у високосному чи невисокосному році народився кожен пасажир.*/
   USE aero
  SELECT *, CASE WHEN YEAR(date_of_birth) % 4 = 0 THEN '--ВИСОКОСНИЙ РІК--' ELSE 'НЕ ВИСОКОСНИЙ РІК' END
  FROM passenger

  /*Визначити вік кожного пасажиру відносно сьогодення*/
  SELECT *,
        DATEDIFF(year, date_of_birth, CAST(GETDATE() as DATE)) as 'Вік',
        DATEDIFF(year, date_of_birth, CAST(GETDATE() as DATE)) -
		CASE 
		WHEN MONTH(date_of_birth)>MONTH(GETDATE()) THEN 1
		WHEN MONTH(date_of_birth)=MONTH(GETDATE()) AND DAY(date_of_birth)>DAY(GETDATE()) THEN 1
		ELSE 0
		END
FROM passenger

/*Таблиця trip. Визначити тривалість рейсу, з урахуванням, що рейс не може летіти довше доби*/
USE aero
SELECT id, town_from, town_to, FORMAT(time_out,'HH:mm') time_out, 
      LEFT(CAST(time_in as TIME),5) as time_in,
	  CASE
	  WHEN time_out<time_in THEN  CONCAT(DATEDIFF(HOUR, time_out, time_in), 'h',
                                         DATEDIFF(MINUTE, time_out, time_in)%60, 'min')
      ELSE
	   CONCAT((DATEDIFF(MINUTE, time_out,'23:59') + DATEDIFF(MINUTE,'00:00',time_in)+1)/60, 'h',
	   (DATEDIFF(MINUTE, time_out,'23:59')+DATEDIFF(MINUTE,'00:00',time_in)+1)%60, 'min')
	  END
	  FROM trip

/* Скільки рейсів виконувалось в КОЖНЕ місто*/
USE aero
SELECT town_to, COUNT(id) 
FROM trip
GROUP BY town_to

/* Скільки рейсів виконувалось по кожному маршруту*/
USE aero
SELECT town_from, town_to, COUNT(id) 
FROM trip
GROUP BY town_from, town_to

/*В якому місяці народилось НАЙМЕНША кількість пасажирів, але більше 1*/
 SELECT TOP 1 WITH TIES MONTH(date_of_birth) as month, COUNT(id) as count_people
 FROM passenger
 GROUP BY MONTH(date_of_birth)
 HAVING COUNT(id)>1
 ORDER BY count_people ASC

 /* Вивести перелік пасажирів, які літали (тільки ті записи, які є одночасно в таблиці Passenger і в таблиці pass_in_trip)*/
 USE aero
 SELECT DISTINCT *
 FROM passenger p
INNER JOIN pass_in_trip pit ON p.id =pit.passenger_id 
ORDER BY p.id

/* Знайти пасажирів, які НЕ ЛІТАЛИ (є в таблиці Passenger і немає в таблиці Pass_in_trip)*/
SELECT DISTINCT *
 FROM passenger p
 LEFT JOIN pass_in_trip pit ON p.id =pit.passenger_id 
 WHERE pit.passenger_id IS NULL
 ORDER BY pit.passenger_id

 /* Вивести перелік компаній, які НЕ літали в Київ*/
 USE aero
 SELECT *
   FROM company c
   LEFT JOIN trip t ON c.id = t.company_id AND town_to LIKE 'Киев'
   WHERE t.id IS NULL

   /* Вивести перелік пасажирів, які НЕ літали на літаку 'BOEING' будь-якої модифікації.*/
   SELECT *
   FROM plane pl
   JOIN trip t ON pl.id = t.plane_id AND pl.plane_name LIKE '%boeing%' -- знайшли рейси, що виконувались BOEING
   JOIN pass_in_trip pit ON pit.trip_id = t.id -- знайшли id_psg, що ЛІТАЛИ НА ЦИХ рейсах
   RIGHT JOIN passenger p ON p.id = pit.passenger_id
   WHERE pl.id  IS NULL

    /*На якому літаку КОЖЕН пасажир літав НАЙБІЛЬШУ кількість разів*/
	 SELECT TOP 1 WITH TIES p.id, p.Surname, pl.id, pl.plane_name, COUNT(t.id) as count_trips,
	      RANK() OVER(PARTITION BY p.id ORDER BY COUNT(t.id) DESC) as rank
		  FROM passenger p
		  JOIN pass_in_trip pit ON p.id = pit.passenger_id
		  JOIN trip t ON t.id = pit.trip_id
		  JOIN plane pl ON pl.id = t.plane_id
     GROUP BY p.id, p.Surname, pl.id, pl.plane_name
	 ORDER BY rank ASC
	 
	 /*В яке місто КОЖЕН пасажир виконав свій ПЕРШИЙ політ*/		  
SELECT TOP 1 WITH TIES  p.id, p.Surname, t.town_to, pit.date, 
       RANK() OVER (PARTITION BY p.id ORDER BY pit.date ASC_ rank
	   LAG(p.id) OVER (ORDER BY pit.date ASC) as lag,
	   CASE WHEN p.id = LAG(p.id) OVER (ORDER BY pit.date ASC) THEN 1000 ELSE 0 END
	   FROM passenger p
	   JOIN pass_in_trip pit ON p.id = pit.passenger_id
	   JOIN  trip t ON t.id = pit.trip_id
	   ORDER BY rank ASC

/*Визначити, в яке місто КОЖНА компанія виконала свій ПЕРЕДОСТАННІЙ РЕЙС*/
SELECT TOP 1 WITH TIES *,
CASE WHEN DENSE_RANK() OVER (ORDER BY pit.date DESC) = 2 THEN 1000 ELSE 0 END as dense_rank
FROM pass_in_trip pit
ORDER BY dense_rank DESC

/*Вивести перелік пасажирів, які НЕ ЛІТАЛИ на Boeing*/
SELECT *
FROM passenger p
WHERE NOT EXISTS (
                      SELECT *
					  FROM pass_in_trip pit
					  JOIN trip t ON pit.trip_id = t.id
					  JOIN plane pl ON pl.id = t.plane_id AND pl.plane_name LIKE '%Boeing%'
					  WHERE pit.passenger_id = p.id
					  )
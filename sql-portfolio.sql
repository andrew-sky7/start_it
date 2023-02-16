/* ������ ��������, � ���� ID �������: ��� 2, ��� 3, ��� 4, ��� 10*/
SELECT id, Surname, name, date_of_birth 'date of birth', id*2 as column1
    FROM passenger p
	WHERE id IN (2,3,4,10)
GO

/* ��������� �� ��������� �����*/
SELECT TOP 10 *
    FROM pass_in_trip
ORDER BY passenger_id ASC, date DESC, trip_id ASC

  /* ���������, � ����������� �� ������������� ���� ��������� ����� �������.*/
   USE aero
  SELECT *, CASE WHEN YEAR(date_of_birth) % 4 = 0 THEN '--���������� в�--' ELSE '�� ���������� в�' END
  FROM passenger

  /*��������� �� ������� �������� ������� ����������*/
  SELECT *,
        DATEDIFF(year, date_of_birth, CAST(GETDATE() as DATE)) as '³�',
        DATEDIFF(year, date_of_birth, CAST(GETDATE() as DATE)) -
		CASE 
		WHEN MONTH(date_of_birth)>MONTH(GETDATE()) THEN 1
		WHEN MONTH(date_of_birth)=MONTH(GETDATE()) AND DAY(date_of_birth)>DAY(GETDATE()) THEN 1
		ELSE 0
		END
FROM passenger

/*������� trip. ��������� ��������� �����, � �����������, �� ���� �� ���� ����� ����� ����*/
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

/* ������ ����� ������������ � ����� ����*/
USE aero
SELECT town_to, COUNT(id) 
FROM trip
GROUP BY town_to

/* ������ ����� ������������ �� ������� ��������*/
USE aero
SELECT town_from, town_to, COUNT(id) 
FROM trip
GROUP BY town_from, town_to

/*� ����� ����� ���������� �������� ������� ��������, ��� ����� 1*/
 SELECT TOP 1 WITH TIES MONTH(date_of_birth) as month, COUNT(id) as count_people
 FROM passenger
 GROUP BY MONTH(date_of_birth)
 HAVING COUNT(id)>1
 ORDER BY count_people ASC

 /* ������� ������ ��������, �� ����� (����� � ������, �� � ��������� � ������� Passenger � � ������� pass_in_trip)*/
 USE aero
 SELECT DISTINCT *
 FROM passenger p
INNER JOIN pass_in_trip pit ON p.id =pit.passenger_id 
ORDER BY p.id

/* ������ ��������, �� �� ˲���� (� � ������� Passenger � ���� � ������� Pass_in_trip)*/
SELECT DISTINCT *
 FROM passenger p
 LEFT JOIN pass_in_trip pit ON p.id =pit.passenger_id 
 WHERE pit.passenger_id IS NULL
 ORDER BY pit.passenger_id

 /* ������� ������ �������, �� �� ����� � ���*/
 USE aero
 SELECT *
   FROM company c
   LEFT JOIN trip t ON c.id = t.company_id AND town_to LIKE '����'
   WHERE t.id IS NULL

   /* ������� ������ ��������, �� �� ����� �� ����� 'BOEING' ����-��� �����������.*/
   SELECT *
   FROM plane pl
   JOIN trip t ON pl.id = t.plane_id AND pl.plane_name LIKE '%boeing%' -- ������� �����, �� ������������ BOEING
   JOIN pass_in_trip pit ON pit.trip_id = t.id -- ������� id_psg, �� ˲���� �� ��� ������
   RIGHT JOIN passenger p ON p.id = pit.passenger_id
   WHERE pl.id  IS NULL

    /*�� ����� ����� ����� ������� ���� ��������� ������� ����*/
	 SELECT TOP 1 WITH TIES p.id, p.Surname, pl.id, pl.plane_name, COUNT(t.id) as count_trips,
	      RANK() OVER(PARTITION BY p.id ORDER BY COUNT(t.id) DESC) as rank
		  FROM passenger p
		  JOIN pass_in_trip pit ON p.id = pit.passenger_id
		  JOIN trip t ON t.id = pit.trip_id
		  JOIN plane pl ON pl.id = t.plane_id
     GROUP BY p.id, p.Surname, pl.id, pl.plane_name
	 ORDER BY rank ASC
	 
	 /*� ��� ���� ����� ������� ������� ��� ������ ����*/		  
SELECT TOP 1 WITH TIES  p.id, p.Surname, t.town_to, pit.date, 
       RANK() OVER (PARTITION BY p.id ORDER BY pit.date ASC_ rank
	   LAG(p.id) OVER (ORDER BY pit.date ASC) as lag,
	   CASE WHEN p.id = LAG(p.id) OVER (ORDER BY pit.date ASC) THEN 1000 ELSE 0 END
	   FROM passenger p
	   JOIN pass_in_trip pit ON p.id = pit.passenger_id
	   JOIN  trip t ON t.id = pit.trip_id
	   ORDER BY rank ASC

/*���������, � ��� ���� ����� ������� �������� ��� ����������Ͳ� ����*/
SELECT TOP 1 WITH TIES *,
CASE WHEN DENSE_RANK() OVER (ORDER BY pit.date DESC) = 2 THEN 1000 ELSE 0 END as dense_rank
FROM pass_in_trip pit
ORDER BY dense_rank DESC

/*������� ������ ��������, �� �� ˲���� �� Boeing*/
SELECT *
FROM passenger p
WHERE NOT EXISTS (
                      SELECT *
					  FROM pass_in_trip pit
					  JOIN trip t ON pit.trip_id = t.id
					  JOIN plane pl ON pl.id = t.plane_id AND pl.plane_name LIKE '%Boeing%'
					  WHERE pit.passenger_id = p.id
					  )
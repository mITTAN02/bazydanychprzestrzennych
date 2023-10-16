--2. Utwórz pustą bazę danych
CREATE DATABASE BazyDanychPrzestrzennych; 
--3. Dodaj funkcjonalności PostGIS’a do bazy poleceniem CREATE EXTENSION postgis;
CREATE EXTENSION postgis;
--4. Na podstawie poniższej mapy utwórz trzy tabele: budynki (id, geometria, nazwa), drogi
--(id, geometria, nazwa), punkty_informacyjne (id, geometria, nazwa).
CREATE TABLE budynki (id INT NOT NULL, geometria GEOMETRY NOT NULL, nazwa VARCHAR(25) NOT NULL);
CREATE TABLE drogi (id INT NOT NULL, geometria GEOMETRY NOT NULL, nazwa VARCHAR(25) NOT NULL);
CREATE TABLE punkty_informacyjne (id INT NOT NULL, geometria GEOMETRY NOT NULL, nazwa VARCHAR(25) NOT NULL);
--5. Współrzędne obiektów oraz nazwy (np. BuildingA) należy odczytać z mapki umieszczonej
--poniżej. Układ współrzędnych ustaw jako niezdefiniowany.

--budynki
INSERT INTO budynki VALUES (1, ST_GeomFromText('POLYGON((8.0 4.0, 10.5 4.0, 10.5 1.5, 8.0 1.5, 8.0 4.0))', 0), 'BuildingA');
INSERT INTO budynki VALUES (2, ST_GeomFromText('POLYGON((4.0 7.0, 6.0 7.0, 6.0 5.0, 4.0 5.0, 4.0 7.0))', 0), 'BuildingB');
INSERT INTO budynki VALUES (3, ST_GeomFromText('POLYGON((3.0 8.0, 5.0 8.0, 5.0 6.0, 3.0 6.0, 3.0 8.0))', 0), 'BuildingC');
INSERT INTO budynki VALUES (4, ST_GeomFromText('POLYGON((9.0 9.0, 10.0 9.0, 10.0 8.0, 9.0 8.0, 9.0 9.0))', 0), 'BuildingD');
INSERT INTO budynki VALUES (5, ST_GeomFromText('POLYGON((1.0 2.0, 2.0 2.0, 2.0 1.0, 1.0 1.0, 1.0 2.0))', 0), 'BuildingF');
SELECT id, ST_AsText(geometria), nazwa FROM budynki;
--drogi 
INSERT INTO drogi VALUES (1, ST_GeomFromText('LINESTRING(0.0 4.5, 12.0 4.5)', 0), 'RoadX');
INSERT INTO drogi VALUES (2, ST_GeomFromText('LINESTRING(7.5 0.0, 7.5 10.5)', 0), 'RoadY');
SELECT id, ST_AsText(geometria), nazwa FROM drogi;
--punkty informacyjne
INSERT INTO punkty_informacyjne VALUES (1, ST_GeomFromText('POINT(1.0 3.5)', 0), 'G');
INSERT INTO punkty_informacyjne VALUES (2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H');
INSERT INTO punkty_informacyjne VALUES (3, ST_GeomFromText('POINT(9.5 6.0)', 0), 'I');
INSERT INTO punkty_informacyjne VALUES (4, ST_GeomFromText('POINT(6.5 6.0)', 0), 'J');
INSERT INTO punkty_informacyjne VALUES (5, ST_GeomFromText('POINT(6.0 9.5)', 0), 'K');
SELECT id, ST_AsText(geometria), nazwa FROM punkty_informacyjne;

--6. Zadania:
--a) Wyznacz całkowitą długość dróg w analizowanym mieście.
SELECT sum(ST_Length(geometria)) as Suma 
FROM drogi;

--b) Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego
--budynek o nazwie BuildingA.
SELECT ST_AsText(geometria) as WKT, ST_Area(geometria) as Pole, ST_Perimeter(geometria) as Obwód
FROM budynki
WHERE nazwa='BuildingA';

--c) Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki
--posortuj alfabetycznie.
SELECT nazwa as Nazwa, ST_Area(geometria) as Pole 
FROM budynki 
ORDER BY nazwa ASC;

--d) Wypisz nazwy i obwody 2 budynków o największej powierzchni.
SELECT nazwa as Nazwa, ST_Perimeter(geometria) as Obwod
FROM budynki 
ORDER BY Obwod DESC LIMIT 2;

--e) Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.
SELECT ST_Distance(budynki.geometria, punkty_informacyjne.geometria) 
FROM budynki, punkty_informacyjne 
WHERE budynki.nazwa='BuildingC' and punkty_informacyjne.nazwa='G';

--f)Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w
--odległości większej niż 0.5 od budynku BuildingB.
SELECT ST_Area(bC.geometria)-ST_Area((ST_Intersection(ST_Buffer(bB.geometria, 0.5), bC.geometria))) as Pole
FROM budynki AS bC, budynki AS bB
WHERE bC.nazwa = 'BuildingC' AND bB.nazwa = 'BuildingB';

--g) Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi
---o nazwie RoadX.
SELECT budynki.nazwa as Budynek
FROM budynki, drogi
WHERE ST_Y(ST_Centroid(budynki.geometria))>(ST_Y(ST_PointN(drogi.geometria, 1))) AND drogi.nazwa='RoadX';

--h). Oblicz pole powierzchni tych części budynku BuildingC i poligonu
--o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch
--obiektów.
SELECT (ST_Area(budynki.geometria)+ST_Area('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))
-2*(ST_Area(ST_Intersection(budynki.geometria, ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8, 4 7))')))) as Pole
FROM budynki
WHERE nazwa='BuildingC';


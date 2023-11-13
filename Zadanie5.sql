--1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
--ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.
CREATE TABLE obiekty (id INT PRIMARY KEY, nazwa VARCHAR(20), geom GEOMETRY);

--obiekt1
INSERT INTO obiekty(id, nazwa, geom) VALUES(1, 'obiekt1',
ST_GeomFromEWKT('SRID=0;COMPOUNDCURVE(
(0 1, 1 1), 
CIRCULARSTRING(1 1, 2 0, 3 1),
CIRCULARSTRING(3 1, 4 2, 5 1),
(5 1, 6 1)
)'))
SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt1';

--obiekt2
INSERT INTO obiekty(id, nazwa, geom) VALUES(2, 'obiekt2',
ST_GeomFromEWKT('SRID=0;CURVEPOLYGON(COMPOUNDCURVE(
(10 6, 14 6),
CIRCULARSTRING(14 6, 16 4, 14 2),
CIRCULARSTRING(14 2, 12 0, 10 2),
(10 2, 10 6)),
CIRCULARSTRING(11 2, 13 2, 11 2)
)'))
SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt2';

--obiekt3
INSERT INTO obiekty(id, nazwa, geom) VALUES(3, 'obiekt3',
ST_GeomFromEWKT('SRID=0;TRIANGLE(
(7 15, 10 17, 12 13, 7 15)
)'))
SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt3';

--ewentualnie
INSERT INTO obiekty(id, nazwa, geom) VALUES(3, 'obiekt3',
ST_GeomFromEWKT('SRID=0;MULTILINESTRING((7 15, 10 17, 12 13, 7 15))'))

--obiekt4
INSERT INTO obiekty(id, nazwa, geom) VALUES(4, 'obiekt4',
ST_GeomFromEWKT('SRID=0;MULTILINESTRING(
(20 20, 25 25), (25 25, 27 24), (27 24, 25 22), (25 22, 26 21), (26 21, 22 19), (22 19, 20.5 19.5))'))	
SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt4';

--obiekt5
INSERT INTO obiekty(id, nazwa, geom) VALUES(5, 'obiekt5',
ST_GeomFromEWKT('SRID=0;MULTIPOINT(30 30 50, 38 32 234)'))
SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt5';

--obiekt6
INSERT INTO obiekty(id, nazwa, geom) VALUES(6, 'obiekt6',
ST_GeomFromEWKT('SRID=0; GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))'))
SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt6';

--Zadanie 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został
--utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.
SELECT ST_Area(ST_BUFFER(ST_ShortestLine(o3.geom, o4.geom),5)) FROM obiekty o3, obiekty o4
WHERE o3.nazwa = 'obiekt3' AND o4.nazwa = 'obiekt4';

--Zadanie 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te
--warunki.
UPDATE obiekty
SET geom = ST_MakePolygon(ST_LineMerge(ST_Collect(geom, 'LINESTRING(20.5 19.5, 20 20)')))
WHERE nazwa = 'obiekt4';

SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt4';

--Zadanie 3.W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty (id, nazwa, geom) VALUES (7, 'obiekt7',
ST_Collect((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'), 
		 (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')));

SELECT ST_CurveToLine(geom) FROM obiekty WHERE nazwa = 'obiekt7';
--Zadanie 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek,
--które zostały utworzone wokół obiektów nie zawierających łuków.
SELECT SUM(ST_Area(ST_Buffer(geom, 5)))
FROM obiekty
WHERE ST_HasArc(obiekty.geom)=false;

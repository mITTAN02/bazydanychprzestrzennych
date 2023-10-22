--Zadanie 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
--położonych w odległości mniejszej niż 1000 jednostek od głównych rzek. Budynki spełniające to
--kryterium zapisz do osobnej tabeli tableB.

CREATE TABLE tableB AS 
SELECT popp.gid, popp.cat, popp.f_codedesc, popp.f_code, popp.type, popp.geom FROM popp, majrivers
WHERE ST_DWithin(popp.geom, majrivers.geom, 1000)
AND popp.f_codedesc = 'Building';
SELECT COUNT(*) FROM tableB;

--SELECT * FROM popp;
--SELECT * FROM majrivers;


--Zadanie 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
--geometrię, a także atrybut elev, reprezentujący wysokość n.p.m
CREATE TABLE airportsNew AS
SELECT name, geom, elev
FROM airports;

--a1)Znajdź lotnisko, które położone jest najbardziej na zachód.
SELECT name, geom, elev
FROM airportsNew
ORDER BY ST_X(geom) ASC LIMIT 1;
				 
--a2)Znajdź lotnisko, które położone jest najbardziej na wschód. 	 
SELECT name, geom, elev
FROM airportsNew
ORDER BY ST_X(geom) DESC LIMIT 1;
				 
--b)Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
--środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
--Wysokość n.p.m. przyjmij dowolną.
INSERT INTO airportsNew VALUES('airportB',
(SELECT ST_LineInterpolatePoint(ST_MakeLine(
(SELECT geom FROM airportsNew ORDER BY ST_X(geom) ASC LIMIT 1),
(SELECT geom FROM airportsNew ORDER BY ST_X(geom) DESC LIMIT 1)), 0.5)), 133);

SELECT * FROM airportsNew WHERE name='airportB';
				 
--6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
--linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_ShortestLine(airport.geom, lake.geom),1000)) AS area
FROM lakes AS lake, airportsNew AS airport
WHERE airport.name = 'AMBLER' AND lake.names = 'Iliamna Lake';
				
--7.Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
--poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).
SELECT trees.vegdesc as drzewa, SUM(ST_Area(trees.geom)) AS powierzchnia
FROM tundra, swamp, trees
WHERE ST_Contains(swamp.geom, trees.geom) OR ST_Contains(tundra.geom, trees.geom)
GROUP BY trees.vegdesc;





 


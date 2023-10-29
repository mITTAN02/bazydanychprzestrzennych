--Zad 1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana
--pomiędzy 2018 a 2019).
CREATE TABLE buildings18_19 AS
SELECT b19.* FROM buildings2018 AS b18, buildings2019 AS b19
WHERE ST_Within(b19.geom, b18.geom) != true AND b19.polygon_id = b18.polygon_id;

SELECT * FROM buildings18_19;

--Zad. 2Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
--wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.
SELECT poi.type, COUNT(*) AS ilosc_poi
FROM poi2018 AS poi
WHERE EXISTS (
  SELECT 1
  FROM buildings18_19 AS new_buildings
  WHERE ST_DWithin(new_buildings.geom, poi.geom, 500)
)
GROUP BY poi.type;

--Zad.3 Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
CREATE TABLE streets_reprojected AS 
SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class,
speed_cat, fr_speed_l, to_speed_l, dir_travel, ST_Transform(geom, 3068) AS geom
FROM karstreets2019;

SELECT * FROM streets_reprojected;

--Zad 4.Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
--Użyj następujących współrzędnych:
--X       Y
--8.36093 49.03174
--8.39876 49.00644
--Przyjmij układ współrzędnych GPS.
CREATE TABLE input_points (pid INT PRIMARY KEY, geom GEOMETRY);
INSERT INTO input_points (pid, geom) VALUES(1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points (pid, geom) VALUES(2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));
SELECT * FROM input_points;

--Zad 5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
--DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText(). 
UPDATE input_points
SET geom = ST_Transform(geom, 3068);
SELECT pid, ST_AsText(geom) FROM input_points;

--Zad 6.Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
--z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
--reprojekcji geometrii, aby była zgodna z resztą tabel.
SELECT * FROM karstnode2019 as karst
WHERE ST_DWithin(ST_Transform(karst.geom, 3068), ST_MakeLine(
(SELECT geom FROM input_points WHERE pid = 1),
(SELECT geom FROM input_points WHERE pid = 2)), 200);

--Zad 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--w odległości 300 m od parków (LAND_USE_A).
SELECT COUNT(poi.type) FROM poi2019 AS poi, land_use_a2019 AS usea
WHERE ST_DWithin(poi.geom, usea.geom, 300) AND poi.type = 'Sporting Goods Store' AND usea.type = 'Park (City/County)';

--Zad. 8 Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
--znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’
CREATE TABLE T2019_KAR_BRIDGES AS
(
	SELECT DISTINCT(ST_Intersection(r.geom, w.geom))
	FROM kar_railways2019 AS r,kar_waterlines2019 AS w
)

SELECT * FROM T2019_KAR_BRIDGES;
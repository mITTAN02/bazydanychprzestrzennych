--Nowa baza danych
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

--Struktury danych
CREATE SCHEMA mitan;
CREATE SCHEMA rasters;
CREATE SCHEMA vectors;

--1.Ładowanie danych rastrowych
----0.Ładowanie wysokości

------Przykład 1 – ładowanie rastra przy użyciu pliku .sql
------C:\"Program Files"\PostgreSQL\15\bin\raster2pgsql.exe  -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\mateu\OneDrive\Pulpit\Bazy_danych_przestrzennych\Zadania\Zajecia6\Dane7\srtm_1arc_v3.tif rasters.dem > C:\Users\mateu\OneDrive\Pulpit\Bazy_danych_przestrzennych\Zadania\Zajecia6\Dane7\dem.sql

------Przykład 2 – ładowanie rastra bezpośrednio do bazy
------C:\"Program Files"\PostgreSQL\15\bin\raster2pgsql.exe  -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\mateu\OneDrive\Pulpit\Bazy_danych_przestrzennych\Zadania\Zajecia6\Dane7\srtm_1arc_v3.tif rasters.dem | psql -d tutorial -h localhost -U postgres -p 5432

------Przykład 3 – załadowanie danych landsat 8 o wielkości kafelka 128x128 bezpośrednio do bazy danych.
------C:\"Program Files"\PostgreSQL\15\bin\raster2pgsql.exe  -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\mateu\OneDrive\Pulpit\Bazy_danych_przestrzennych\Zadania\Zajecia6\Dane7\Landsat8_L1TP_RGBN.TIF rasters.landsat8 | psql -d tutorial -h localhost -U postgres -p 5432



----1.Tworzenie rastrów z istniejących rastrów i interakcja z wektorami

------Przykład 1 - ST_Intersects
CREATE TABLE mitan.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

------a) dodanie serial primary key:
alter table mitan.intersects
add column rid SERIAL PRIMARY KEY;

------b)utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON mitan.intersects
USING gist (ST_ConvexHull(rast));

------c)dodanie raster constraints:
SELECT AddRasterConstraints('mitan'::name,
'intersects'::name,'rast'::name);


------ Przykład 2 - St_Clip

------a)Obcinanie rastra na podstawie wektora.
CREATE TABLE mitan.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';


------ Przykład 3 - ST_Union

------a) Połączenie wielu kafelków w jeden raster
CREATE TABLE mitan.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


----2.Tworzenie rastrów z wektorów (rastrowanie)

------Przykład 1 - ST_AsRaster
CREATE TABLE mitan.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

------Przykład 2 - ST_Union
DROP TABLE mitan.porto_parishes; --> drop table porto_parishes first
CREATE TABLE mitan.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

------Przykład 3 - ST_Tile
DROP TABLE mitan.porto_parishes; --> drop table porto_parishes first
CREATE TABLE mitan.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


----3.Konwertowanie rastrów na wektory (wektoryzowanie)
------Przykład 1 - ST_Intersection
create table mitan.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

------Przykład 2 - ST_DumpAsPolygons
CREATE TABLE mitan.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


----4. Analiza rastrów

------Przykład 1 - ST_Band
CREATE TABLE mitan.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

------Przykład 2 - ST_Clip
CREATE TABLE mitan.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

------Przykład 3 - ST_Slope
CREATE TABLE mitan.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM mitan.paranhos_dem AS a;

------Przykład 4 - ST_Reclass
CREATE TABLE mitan.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM mitan.paranhos_slope AS a;

------Przykład 5 - ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM mitan.paranhos_dem AS a;

------Przykład 6 - ST_SummaryStats oraz Union
SELECT st_summarystats(ST_Union(a.rast))
FROM mitan.paranhos_dem AS a;

------Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM mitan.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

------Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

------Przykład 9 - ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


----4.Topographic Position Index (TPI)
------Przykład 10 - ST_TPI
create table mitan.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;
-------Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON mitan.tpi30
USING gist (ST_ConvexHull(rast));
-------Dodanie constraintów:
SELECT AddRasterConstraints('mitan'::name,
'tpi30'::name,'rast'::name);

-----Problem do samodzielnego rozwiązania
------Przetwarzanie poprzedniego zapytania może potrwać dłużej niż minutę, a niektóre zapytania mogą potrwać zbyt długo. W celu skrócenia czasu przetwarzania czasami można ograniczyć obszar
------zainteresowania i obliczyć mniejszy region. Dostosuj zapytanie z przykładu 10, aby przetwarzać tylko gminę Porto. Musisz użyć ST_Intersects, sprawdź Przykład 1 - ST_Intersects w celach
------informacyjnych. Porównaj różne czasy przetwarzania. Na koniec sprawdź wynik w QGIS.

create table mitan.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'
-------Dodanie indeksu przestrzennego:
CREATE INDEX idx_tpi30_porto_rast_gist ON mitan.tpi30_porto
USING gist (ST_ConvexHull(rast));
-------Dodanie constraintów:
SELECT AddRasterConstraints('mitan'::name,
'tpi30_porto'::name,'rast'::name);

--2.Algebra map
------Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE mitan.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
) AS rast
FROM r;
-------Poniższe zapytanie utworzy indeks przestrzenny na wcześniej stworzonej tabeli:
CREATE INDEX idx_porto_ndvi_rast_gist ON mitan.porto_ndvi
USING gist (ST_ConvexHull(rast));
-------Dodanie constraintów:
SELECT AddRasterConstraints('mitan'::name,
'porto_ndvi'::name,'rast'::name);



------Przykład 2 – Funkcja zwrotna
create or replace function mitan.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;



-------W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE mitan.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'mitan.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;
-------Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON mitan.porto_ndvi2
USING gist (ST_ConvexHull(rast));
-------Dodanie constraintów:
SELECT AddRasterConstraints('mitan'::name,
'porto_ndvi2'::name,'rast'::name);


----3. Eksport danych
------Przykład 1 - ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM mitan.porto_ndvi;

------Przykład 2 - ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM mitan.porto_ndvi;
SELECT ST_GDALDrivers();

------Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu (large object,lo) 
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM mitan.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\myraster.tiff')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

------Przykład 4 - Użycie Gdal
-------w terminalu OSGeo4W Shell:
-------gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=tutorial user=postgres password= schema=mitan table=porto_ndvi mode=2" D:\porto_ndvi.tiff

-------(nie dziala: error1: IReadBlock failed at X offset 0, Y offset 0)















--Zad 1.Podaj pole powierzchni wszystkich lasów o charakterze mieszanym. 
SELECT SUM(ST_Area(geom)) FROM trees
WHERE trees.vegdesc = 'Mixed Trees';

--Zad 2. Podziel warstwę trees na trzy warstwy. Na każdej z nich umieść inny typ lasu. Zapisz wyniki do osobnych tabel.
SELECT * FROM trees 
WHERE trees.vegdesc='Deciduous';

SELECT * FROM trees 
WHERE trees.vegdesc='Evergreen';

SELECT * FROM trees 
WHERE trees.vegdesc='Mixed Trees';

--Zad.3 Oblicz długość linii kolejowych dla regionu Matanuska-Susitna. 
SELECT SUM(ST_Length(ST_Intersection(rail.geom, region.geom))) FROM railroads rail, regions region
WHERE region.name_2 = 'Matanuska-Susitna';

--Zad.4  Oblicz, na jakiej średniej wysokości nad poziomem morza położone są lotniska o charakterze militarnym. 
SELECT AVG(airports.elev) FROM airports 
WHERE airports.use = 'Military';

--Ile jest takich lotnisk?
SELECT COUNT(*) FROM airports
WHERE airports.use = 'Military';

-- Usuń z warstwy airports lotniska o charakterze militarnym, które są dodatkowo położone
--powyżej 1400 m n.p.m.
DELETE FROM airports WHERE airports.use = 'Military' AND airports.elev >1400;

-- Ile było takich lotnisk? 
SELECT COUNT(*) FROM airports
WHERE airports.use = 'Military';

--Sprawdź, czy zmiany są widoczne w tabeli bazy danych.
SELECT COUNT(*) FROM airports
WHERE airports.use = 'Military' AND airports.elev >1400;

--Zad.5 Utwórz warstwę (tabelę), na której znajdować się będą jedynie budynki położone w regionie Bristol Bay
--(wykorzystaj warstwę popp). w
CREATE TABLE bristol_buildings AS
SELECT popp.* FROM popp, regions
WHERE ST_Within(popp.geom,regions.geom) AND popp.f_codedesc = 'Building' AND regions.name_2 = 'Bristol Bay';

--Podaj liczbę budynków
SELECT COUNT(*) FROM bristol_buildings;

--Zad.6 W tabeli wynikowej z poprzedniego zadania zostaw tylko te budynki, które są położone nie dalej niż 100 km od
--rzek (rivers). Ile jest takich budynków? 
SELECT COUNT(*) FROM bristol_buildings bb, rivers
WHERE ST_DWithin(rivers.geom, bb.geom, 100000);

--Zad.7 Sprawdź w ilu miejscach przecinają się rzeki (majrivers) z liniami kolejowymi (railroads). 
SELECT COUNT(DISTINCT (ST_Intersection(majrivers.geom, railroads.geom))) FROM majrivers, railroads;

--Zad.8 Wydobądź węzły dla warstwy railroads. Ile jest takich węzłów? Zapisz wynik w postaci osobnej tabeli w bazie
--danych.
SELECT COUNT(*) FROM wezly;

--Zad.10 Ile wierzchołków zostało zredukowanych? 
SELECT SUM(ST_NPoints(geom)) FROM swamp; --7469 wierchołków
SELECT SUM(ST_NPoints(geom)) FROM uproszczone_swamps; --6661 wierzchołków
--Różnica: 808 wierzchołków, i tyle wierzchołków zostało zredukowanych.

--Czy zmieniło się pole powierzchni całkowitej poligonów?
SELECT SUM(ST_Area(geom)) FROM swamp; --Pole: 266080392628.23563
SELECT SUM(ST_Area(geom)) FROM uproszczone_swamps; --Pole: 266082466575.26416
--Po uproszczeniu pole zwiększyło się o 2 073 947,02853.
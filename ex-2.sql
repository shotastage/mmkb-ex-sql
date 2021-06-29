-- PSQL Script --

-- INITIALIZE TABLES --
DROP TABLE IF EXISTS stations;
DROP TABLE IF EXISTS place;
DROP TABLE IF EXISTS railway_relations;



-- DECLARED FUNCTIONS --
CREATE OR REPLACE FUNCTION gis_distance(point, point)
RETURNS double precision AS
$BODY$
SELECT 2 * R * ASIN( d / 2 / R )
FROM (
SELECT SQRT((x1 -x2)^2 + (y1 -y2)^2 + (z1 -z2)^2) AS d, R FROM (
SELECT c.R
, c.R* COS(pi() * l1.lat/180) * COS(pi() * l1.lng/180) AS x1
, c.R* COS(pi() * l1.lat/180) * SIN(pi() * l1.lng/180) AS y1
, c.R* SIN(pi() * l1.lat/180) AS z1
, c.R* COS(pi() * l2.lat/180) * COS(pi() * l2.lng/180) AS x2
, c.R* COS(pi() * l2.lat/180) * SIN(pi() * l2.lng/180) AS y2
, c.R* SIN(pi() * l2.lat/180) AS z2
FROM (SELECT $1[0] AS lat, $1[1] AS lng) AS l1
, (SELECT $2[0] AS lat, $2[1] AS lng) AS l2
, (SELECT 6378.137 AS R) AS c
) trig
) sq
$BODY$
LANGUAGE sql;



CREATE OR REPLACE FUNCTION create_tranfer() RETURNS "trigger" AS
$BODY$
declare
    transfer text[];
begin
    
    SELECT array_agg(c2.sid) INTO transfer FROM stations c2
    WHERE c2.sid = new.sid AND gis_distance(new.location, c2.location) < 0.25 GROUP BY gis_distance(new.location, c2.location);


    INSERT INTO railway_relations VALUES (new.id, new.sid, transfer);
return new;
end;
$BODY$
LANGUAGE plpgsql;


-- STATION TABLE--
CREATE TABLE stations (
    id text,
    sid text,
    name text,
    location point
);

INSERT INTO stations VALUES ('1', 'K1', 'KANNAI', '(35.444136, 139.635981)');
INSERT INTO stations VALUES ('2', 'S1', 'SAKURAGICHO', '(35.450840, 139.631136)');
INSERT INTO stations VALUES ('3', 'Y1', 'YOKOHAMA', '(35.466024, 139.622677)');
INSERT INTO stations VALUES ('4', 'T1', 'TAKASHIMACHO', '(35.459080, 139.623374)');
INSERT INTO stations VALUES ('5', 'K1', 'B-KANNAI', '(35.445917, 139.635683)');
INSERT INTO stations VALUES ('6', 'I1', 'ISEZAKI-CHOJYAMACHI', '(35.441044, 139.633008)');
INSERT INTO stations VALUES ('7', 'S1', 'SHIN-TAKASHIMA', '(35.462043, 139.626582)');
INSERT INTO stations VALUES ('8', 'M1', 'MINATOMIRAI', '(35.457209, 139.632966)');
INSERT INTO stations VALUES ('9', 'B1', 'BASHAMICHI', '(35.449966, 139.636613)');
INSERT INTO stations VALUES ('10','N1', 'NIHONOODORI', '(35.446759, 139.642711)');
INSERT INTO stations VALUES ('11','M1', 'MOTOMACHI-CHUKAGAI', '(35.442296, 139.650651)');
INSERT INTO stations VALUES ('12','I2', 'ISHIKAWA-CHO', '(35.438745, 139.642987)');

CREATE TRIGGER create_tranfer
  AFTER INSERT
  ON stations
  FOR EACH ROW
  EXECUTE PROCEDURE create_tranfer();



CREATE TABLE railway_relations (
    id text,
    sid text, 
    transfer text[]
);




INSERT INTO stations VALUES ('1', 'K1', 'KANNAI');
INSERT INTO stations VALUES ('2', 'S1', 'SAKURAGICHO');
INSERT INTO stations VALUES ('3', 'Y1', 'YOKOHAMA');
INSERT INTO stations VALUES ('4', 'T1', 'TAKASHIMACHO');
INSERT INTO stations VALUES ('5', 'K1', 'B-KANNAI');
INSERT INTO stations VALUES ('6', 'I1', 'ISEZAKI-CHOJYAMACHI');
INSERT INTO stations VALUES ('7', 'S1', 'SHIN-TAKASHIMA');
INSERT INTO stations VALUES ('8', 'M1', 'MINATOMIRAI');
INSERT INTO stations VALUES ('9', 'B1', 'BASHAMICHI');
INSERT INTO stations VALUES ('10','N1', 'NIHONOODORI');
INSERT INTO stations VALUES ('11','M1', 'MOTOMACHI-CHUKAGAI');
INSERT INTO stations VALUES ('12','I2', 'ISHIKAWA-CHO');



-- PLACE TABLE--
CREATE TABLE place (
    id text,
    name text,
    type varchar(30), location point
);
INSERT INTO place VALUES ('1', 'RED BRICK WAREHOUSE', 'shopping', '(35.452604, 139.642882)');
INSERT INTO place VALUES ('2', 'YOKOHAMA HUMMER HEAD', 'shopping', '(35.456038, 139.641981)');
INSERT INTO place VALUES ('3', 'COSMO CLOCK 21', 'amusement', '(35.455323, 139.636676)');
INSERT INTO place VALUES ('4', 'YOKOHAMA LANDMARK TOWER', 'sightseeing', '(35.454885, 139.631252)');
INSERT INTO place VALUES ('5', 'YOKOHAMA MARINE TOWER', 'sightseeing', '(35.443956, 139.650920)');
INSERT INTO place VALUES ('6', 'YOKOHAMA STADIUM', 'amusement', '(35.443138, 139.640082)');
INSERT INTO place VALUES ('7', 'OSANBASHI PIER', 'sightseeing', '(35.451648, 139.647628)');
INSERT INTO place VALUES ('8', 'ZONOHONA PARK', 'sightseeing', '(35.450091, 139.642920)');
INSERT INTO place VALUES ('9', 'UNGA PARK', 'sightseeing', '(35.453145, 139.638301)');
INSERT INTO place VALUES ('10', 'KANTEIBYO', 'sightseeing', '(35.442433, 139.645202)');



-- RESULT DIVISION --

-- Find stations near the designated place in order of distance. --
SELECT c2.*, gis_distance(c1.location, c2.location) AS distance FROM place c1, stations c2
WHERE c1.name = 'YOKOHAMA LANDMARK TOWER' ORDER BY distance ASC;


SELECT c2.*, gis_distance(c1.location, c2.location) AS distance FROM stations c1, place c2
WHERE c1.name = 'MINATOMIRAI' AND c2.type = 'amusement'
ORDER BY distance ASC;


SELECT c2.*, gis_distance(c1.location, c2.location) AS distance FROM stations c1, place c2
WHERE c1.name = 'MINATOMIRAI' AND c2.type = 'sightseeing'
ORDER BY distance ASC;

SET CHARACTER_SET_CLIENT = utf8mb4;
SET CHARACTER_SET_CONNECTION = utf8mb4;

USE isuride;

SELECT "ALTER TABLE";

-- chairs に locations を統合
ALTER TABLE chairs 
  ADD COLUMN latitude INTEGER DEFAULT NULL,
  ADD COLUMN longitude INTEGER DEFAULT NULL,
  ADD COLUMN total_distance INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN total_distance_updated_at DATETIME(6) DEFAULT NULL;

SELECT "total_distance";

CREATE OR REPLACE VIEW distances AS 
  SELECT
    chair_id,
    SUM(IFNULL(distance, 0)) AS total_distance,
    MAX(created_at)          AS total_distance_updated_at
  FROM (
    SELECT 
      chair_id,
      created_at,
      ABS(latitude - LAG(latitude) OVER (PARTITION BY chair_id ORDER BY created_at)) +
      ABS(longitude - LAG(longitude) OVER (PARTITION BY chair_id ORDER BY created_at)) AS distance
    FROM chair_locations) tmp
  GROUP BY chair_id;

UPDATE chairs
  JOIN distances ON distances.chair_id = chairs.id
  SET
    chairs.total_distance = distances.total_distance,
    chairs.total_distance_updated_at = distances.total_distance_updated_at;

UPDATE chairs SET
  latitude = (SELECT latitude FROM chair_locations WHERE chair_locations.chair_id = chairs.id ORDER BY created_at DESC LIMIT 1),
  longitude = (SELECT longitude FROM chair_locations WHERE chair_locations.chair_id = chairs.id ORDER BY created_at DESC LIMIT 1),
  total_distance_updated_at = (SELECT created_at FROM chair_locations WHERE chair_locations.chair_id = chairs.id ORDER BY created_at DESC LIMIT 1);

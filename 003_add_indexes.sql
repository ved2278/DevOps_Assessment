-- Optimizes:
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
-- city is an equality filter and created_at is a range filter, so a
-- composite btree index on (city, created_at) lets Postgres do a single
-- index range scan instead of a sequential scan over the whole table.
-- org_id, status and amount are added as INCLUDE columns (not part of the
-- search key) so the query can be answered as an index-only scan without
-- going back to the heap for every matching row. See README.md for the
-- full explanation and EXPLAIN ANALYZE comparison.
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

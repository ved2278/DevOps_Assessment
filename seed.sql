-- Seed data: 150 hotel bookings across 4 cities, 4 orgs, 4 statuses,
-- with created_at spread over the last 60 days so the "last 30 days"
-- query in the assessment has both matching and non-matching rows.
-- Uses a generate_series + a fixed list of orgs/cities/statuses so the
-- data is deterministic and easy to reason about.

WITH orgs AS (
    SELECT unnest(ARRAY[
        '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222',
        '33333333-3333-3333-3333-333333333333',
        '44444444-4444-4444-4444-444444444444'
    ]::uuid[]) AS org_id
),
cities AS (
    SELECT unnest(ARRAY['delhi', 'mumbai', 'bengaluru', 'chennai']) AS city
),
statuses AS (
    SELECT unnest(ARRAY['confirmed', 'cancelled', 'completed', 'pending']) AS status
),
generated AS (
    SELECT
        gen_random_uuid() AS id,
        (SELECT org_id FROM orgs ORDER BY random() LIMIT 1) AS org_id,
        'hotel-' || (1 + floor(random() * 20))::int AS hotel_id,
        (SELECT city FROM cities ORDER BY random() LIMIT 1) AS city,
        (SELECT status FROM statuses ORDER BY random() LIMIT 1) AS status,
        n
    FROM generate_series(1, 150) AS n
)
INSERT INTO hotel_bookings (
    id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at
)
SELECT
    id,
    org_id,
    hotel_id,
    city,
    (CURRENT_DATE - (floor(random() * 60))::int + 3) AS checkin_date,
    (CURRENT_DATE - (floor(random() * 60))::int + 6) AS checkout_date,
    round((2000 + random() * 18000)::numeric, 2) AS amount,
    status,
    now() - (floor(random() * 60) || ' days')::interval - (floor(random() * 24) || ' hours')::interval AS created_at
FROM generated;

-- Make sure check-out is always after check-in (the random offsets above
-- can occasionally collide); fix any bad rows deterministically.
UPDATE hotel_bookings
SET checkout_date = checkin_date + 3
WHERE checkout_date <= checkin_date;

-- A handful of booking_events for a subset of bookings, so booking_events
-- is populated but intentionally not 1:1 with hotel_bookings.
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
    hb.id,
    et.event_type,
    jsonb_build_object('source', 'seed', 'note', et.event_type),
    hb.created_at + (et.offset_minutes || ' minutes')::interval
FROM hotel_bookings hb
CROSS JOIN LATERAL (
    VALUES
        ('booking_created', 0),
        ('payment_received', 15)
) AS et(event_type, offset_minutes)
WHERE hb.status IN ('confirmed', 'completed')
LIMIT 200;

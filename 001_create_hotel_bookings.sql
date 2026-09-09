-- Core booking table. One row per hotel reservation.
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- provides gen_random_uuid()

CREATE TABLE IF NOT EXISTS hotel_bookings (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id        UUID NOT NULL,
    hotel_id      VARCHAR(100) NOT NULL,
    city          VARCHAR(100) NOT NULL,
    checkin_date  DATE NOT NULL,
    checkout_date DATE NOT NULL,
    amount        NUMERIC(12, 2) NOT NULL,
    status        VARCHAR(50) NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT chk_checkout_after_checkin CHECK (checkout_date > checkin_date)
);

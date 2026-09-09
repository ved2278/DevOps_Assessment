-- Event log for bookings (created, confirmed, cancelled, payment_received, ...).
CREATE TABLE IF NOT EXISTS booking_events (
    id         BIGSERIAL PRIMARY KEY,
    booking_id UUID NOT NULL REFERENCES hotel_bookings (id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    payload    JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Events are almost always looked up by booking, so index the FK.
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id ON booking_events (booking_id);

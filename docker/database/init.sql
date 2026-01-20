CREATE TABLE IF NOT EXISTS service_requests (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20),
    service_type VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)

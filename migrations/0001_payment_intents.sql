CREATE TABLE IF NOT EXISTS payment_intents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL,
  provider TEXT NOT NULL CHECK (provider IN ('chapa', 'telebirr', 'cbe_birr')),
  merchant_reference TEXT NOT NULL UNIQUE,
  idempotency_key TEXT NOT NULL,
  amount_minor INTEGER NOT NULL CHECK (amount_minor >= 100),
  currency TEXT NOT NULL CHECK (currency = 'ETB'),
  customer_email TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('initializing', 'pending', 'paid', 'failed')),
  checkout_url TEXT,
  provider_reference TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (uid, idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_payment_intents_uid_created
  ON payment_intents (uid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_intents_status
  ON payment_intents (status, updated_at);

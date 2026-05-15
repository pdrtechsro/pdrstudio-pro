-- ════════════════════════════════════════════════════════════════════
-- PDR STUDIO PRO — DATABASE SCHEMA
-- Eseguire in Supabase → SQL Editor → New Query → Run
-- ════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────
-- TABELLE
-- ──────────────────────────────────────────────────

-- Pratiche (preventivi/veicoli)
CREATE TABLE practices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Clienti
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Cicli Lavorativi (campagne grandine)
CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Assicurazioni custom apprese
CREATE TABLE custom_insurances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, name)
);

-- Impostazioni utente (dati azienda, matrice, smontaggio, coefficiente)
-- Una sola riga per utente (key-value singola)
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  settings JSONB DEFAULT '{}',
  matrix JSONB DEFAULT '[]',
  deg JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ──────────────────────────────────────────────────
-- INDICI per performance
-- ──────────────────────────────────────────────────
CREATE INDEX practices_user_id_idx ON practices(user_id);
CREATE INDEX practices_updated_at_idx ON practices(updated_at DESC);
CREATE INDEX clients_user_id_idx ON clients(user_id);
CREATE INDEX campaigns_user_id_idx ON campaigns(user_id);
CREATE INDEX custom_insurances_user_id_idx ON custom_insurances(user_id);

-- ──────────────────────────────────────────────────
-- ROW LEVEL SECURITY (ognuno vede solo i suoi dati)
-- ──────────────────────────────────────────────────
ALTER TABLE practices ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_insurances ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Policies: ogni utente legge/scrive solo le proprie righe
CREATE POLICY "Users manage their practices" ON practices
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage their clients" ON clients
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage their campaigns" ON campaigns
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage their insurances" ON custom_insurances
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage their settings" ON user_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TRIGGER: auto-aggiornamento updated_at
-- ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER practices_updated_at BEFORE UPDATE ON practices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER clients_updated_at BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER campaigns_updated_at BEFORE UPDATE ON campaigns
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER user_settings_updated_at BEFORE UPDATE ON user_settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ──────────────────────────────────────────────────
-- FINE SCHEMA
-- ──────────────────────────────────────────────────
-- Dopo aver eseguito questo SQL, vai su:
-- Authentication → Settings → "Allow new users to sign up" → DISABLE
-- (così solo email autorizzate manualmente da te potranno registrarsi)
-- Per autorizzare nuovi utenti: Authentication → Users → "Invite user"

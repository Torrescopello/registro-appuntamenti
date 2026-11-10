// Collegamento al database Supabase del Registro Sposi.
// Li trovi in Supabase > Project Settings > API (o Data API):
//   - Project URL           -> SUPABASE_URL
//   - Project API key "anon public" -> SUPABASE_ANON_KEY
// La chiave "anon" è pubblica per natura: i dati sono protetti dalle regole
// di accesso del database, non da questa chiave. NON incollare mai qui la
// chiave "service_role".
// Finché i valori restano vuoti, l'app si apre in modalità prova con dati di esempio.
window.REGISTRO_CONFIG = {
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: ''
};

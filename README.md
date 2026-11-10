# Registro Sposi · Torre di Scopello

Web app per annotare le coppie dopo il primo contatto, gli appuntamenti (con chi li ha fatti), lo storico di ogni trattativa e le statistiche mensili e annuali di conversione a contratto.

Si apre dal browser su iPad, telefono e computer e si installa sulla schermata Home. Ognuno entra con la propria email e password.

## Com'è fatta

- `index.html`: l'app (pagina unica, nessuna compilazione).
- `config.js`: indirizzo e chiave pubblica del database Supabase. Se vuoti, l'app parte in **modalità prova** con dati di esempio.
- `supabase/schema.sql`: tabelle, regole di accesso e controllo delle registrazioni.
- `lib/`: libreria ufficiale Supabase (versione 2.45.4), inclusa per non dipendere da servizi esterni.
- `manifest.json`, `sw.js`, `icons/`: installazione sulla schermata Home.

## Sicurezza

- I dati delle coppie si leggono solo dopo l'accesso, e solo se l'email è attiva nella tabella `staff` (la Squadra).
- Solo le email presenti nella Squadra possono creare un account.
- I collaboratori lavorano su coppie, appuntamenti e storia; gli amministratori gestiscono la Squadra e possono eliminare le schede.
- La chiave in `config.js` è la chiave pubblica `anon`: è normale che sia visibile. Non inserire mai la chiave `service_role`.

## Messa in funzione

1. **Supabase**: crea un progetto (regione Europa), apri *SQL Editor*, incolla `supabase/schema.sql`, scrivi la tua email nella sezione «PRIMO AMMINISTRATORE» e premi *Run*.
2. **Supabase > Authentication > URL Configuration**: imposta *Site URL* sull'indirizzo dell'app (es. `https://NOME-ACCOUNT.github.io/registro-sposi/`).
3. **Supabase > Project Settings > API**: copia *Project URL* e la chiave *anon public* dentro `config.js`.
4. **GitHub > Settings > Pages**: pubblica dal ramo `main`, cartella `/ (root)`.
5. Apri l'app, scegli **Primo accesso**, usa la tua email, conferma dal messaggio ricevuto ed entra.
6. Dalla scheda **Squadra** aggiungi i colleghi e mandagli il link.

## Come contano le statistiche

- Contano solo gli appuntamenti con esito **Svolto**.
- Ogni coppia è attribuita al mese del suo **primo appuntamento svolto**, quindi la somma dei mesi è uguale al totale dell'anno.
- **Concluso a contratto** = stato «Contratto firmato». La colonna «Contratti firmati nel periodo» usa la data di firma.
- Le tabelle per persona e per canale mostrano quante coppie ciascuno ha seguito; una coppia vista da due persone compare in entrambe le righe.

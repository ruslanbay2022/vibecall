-- Step 4.4: WhatsApp-style delivery ticks (sent / delivered / read).
alter table public.messages
  add column if not exists delivered_at timestamptz;

# RED//CORE

RED//CORE is an academic mission board with per-player XP, achievements, and a shared finished-work gallery. The dark RED//CORE interface is a static page; shared data is provided by Supabase.

## Enable the shared network

1. Create a Supabase project.
2. In the Supabase SQL Editor, run [`supabase/setup.sql`](supabase/setup.sql).
3. In Supabase Authentication settings, enable anonymous sign-ins.
4. Open RED//CORE, select the gear button, and enter the project's URL and anon/publishable key from Project Settings → API.
5. Give every user the same hosted RED//CORE page and the same project URL/key. The app remembers the connection on that browser and reconnects automatically.

Only use the browser-safe anon/publishable key. Never enter a service-role key. The setup script restricts mission editing to its creator, keeps completion records private to each player, and makes uploaded archive images public so network members can view them. Uploads are limited to 10 MB and common web image types.

## Local mode

Without a configured Supabase project, assignments remain in this browser and cannot be shared with other visitors. The export/import buttons can move a local backup between browsers, but do not sync it.
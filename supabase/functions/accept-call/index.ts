import { getUser } from "../_shared/auth.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { issueLiveKitToken } from "../_shared/livekit.ts";
import { createServiceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }
  try {
    const { user } = await getUser(req);
    const { invitationId } = await req.json();
    if (!invitationId) {
      return new Response("Bad request", { status: 400, headers: corsHeaders });
    }

    const adminSupa = createServiceClient();
    const { data: inv, error: fetchErr } = await adminSupa
      .from("call_invitations")
      .select("*")
      .eq("id", invitationId)
      .maybeSingle();
    if (fetchErr) throw fetchErr;
    if (!inv) {
      return new Response(JSON.stringify({ error: "not_found" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (inv.receiver_id !== user.id) {
      return new Response(JSON.stringify({ error: "forbidden" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (inv.state !== "ringing") {
      return new Response(JSON.stringify({ error: "invalid_state" }), {
        status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: updateErr } = await adminSupa
      .from("call_invitations")
      .update({ state: "accepted" })
      .eq("id", invitationId);
    if (updateErr) throw updateErr;

    return new Response(JSON.stringify({
      token: await issueLiveKitToken(user.id, inv.room_name, inv.has_video),
      wsUrl: Deno.env.get("LIVEKIT_WS_URL"),
      roomName: inv.room_name,
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (e) {
    if (e instanceof Response) return e;
    return new Response(String(e), { status: 500, headers: corsHeaders });
  }
});

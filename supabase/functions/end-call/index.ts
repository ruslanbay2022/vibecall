import { getUser } from "../_shared/auth.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { user } = await getUser(req);
    const { invitationId, durationSec } = await req.json();
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
    if (inv.caller_id !== user.id && inv.receiver_id !== user.id) {
      return new Response(JSON.stringify({ error: "forbidden" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const outcomeMap: Record<string, string> = {
      accepted: "accepted",
      cancelled: "cancelled",
      rejected: "rejected",
      missed: "missed",
      timeout: "timeout",
      busy: "busy",
    };
    const outcome = outcomeMap[inv.state] ?? "cancelled";

    const { error: historyErr } = await adminSupa.from("call_history").insert({
      room_name: inv.room_name,
      caller_id: inv.caller_id,
      receiver_id: inv.receiver_id,
      outcome,
      has_video: inv.has_video,
      duration_sec: durationSec ?? null,
      started_at: inv.created_at,
      ended_at: new Date().toISOString(),
    });
    if (historyErr) throw historyErr;

    const { error: deleteErr } = await adminSupa
      .from("call_invitations")
      .delete()
      .eq("id", invitationId);
    if (deleteErr) throw deleteErr;

    return new Response(null, { status: 204, headers: corsHeaders });
  } catch (e) {
    if (e instanceof Response) return e;
    return new Response(String(e), { status: 500, headers: corsHeaders });
  }
});

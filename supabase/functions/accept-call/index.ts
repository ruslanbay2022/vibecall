import { AccessToken } from "https://esm.sh/livekit-server-sdk@2.6.1";
import { getUser } from "../_shared/auth.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { createServiceClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
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

    const at = new AccessToken(
      Deno.env.get("LIVEKIT_API_KEY")!,
      Deno.env.get("LIVEKIT_API_SECRET")!,
      { identity: user.id, ttl: 60 * 60 },
    );
    at.addGrant({
      roomJoin: true, room: inv.room_name,
      canPublish: true, canSubscribe: true, canPublishData: true,
      canPublishSources: inv.has_video
        ? ["camera", "microphone", "screen_share", "screen_share_audio"]
        : ["microphone"],
    });

    return new Response(JSON.stringify({
      token: await at.toJwt(),
      wsUrl: Deno.env.get("LIVEKIT_WS_URL"),
      roomName: inv.room_name,
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (e) {
    if (e instanceof Response) return e;
    return new Response(String(e), { status: 500, headers: corsHeaders });
  }
});

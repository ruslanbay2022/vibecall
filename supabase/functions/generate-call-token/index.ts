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
    const { receiverId, hasVideo } = await req.json();
    if (!receiverId || typeof hasVideo !== "boolean") {
      return new Response("Bad request", { status: 400, headers: corsHeaders });
    }

    if (receiverId === user.id) {
      return new Response(JSON.stringify({ error: "self_call" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminSupa = createServiceClient();
    const { data: busy } = await adminSupa.from("call_invitations")
      .select("id").eq("receiver_id", receiverId).eq("state", "ringing").maybeSingle();
    if (busy) return new Response(JSON.stringify({ error: "busy" }), {
      status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

    const ids = [user.id, receiverId].sort();
    const roomName = `dm_${ids[0]}__${ids[1]}_${Date.now()}`;

    const { error: insertErr } = await adminSupa.from("call_invitations").insert({
      room_name: roomName, caller_id: user.id, receiver_id: receiverId, has_video: hasVideo,
    });
    if (insertErr) {
      const msg = insertErr.message ?? "";
      if (insertErr.code === "23505" || msg.includes("call_inv_one_active_per_receiver")) {
        return new Response(JSON.stringify({ error: "busy" }), {
          status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      throw insertErr;
    }

    return new Response(JSON.stringify({
      token: await issueLiveKitToken(user.id, roomName, hasVideo),
      wsUrl: Deno.env.get("LIVEKIT_WS_URL"),
      roomName,
    }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (e) {
    if (e instanceof Response) return e;
    return new Response(String(e), { status: 500, headers: corsHeaders });
  }
});

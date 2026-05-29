import { AccessToken, TrackSource } from "https://esm.sh/livekit-server-sdk@2.6.1";

function publishSources(hasVideo: boolean): TrackSource[] {
  return hasVideo
    ? [
      TrackSource.CAMERA,
      TrackSource.MICROPHONE,
      TrackSource.SCREEN_SHARE,
      TrackSource.SCREEN_SHARE_AUDIO,
    ]
    : [TrackSource.MICROPHONE];
}

export async function issueLiveKitToken(
  identity: string,
  roomName: string,
  hasVideo: boolean,
): Promise<string> {
  const at = new AccessToken(
    Deno.env.get("LIVEKIT_API_KEY")!,
    Deno.env.get("LIVEKIT_API_SECRET")!,
    { identity, ttl: 60 * 60 },
  );
  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
    canPublishSources: publishSources(hasVideo),
  });
  return await at.toJwt();
}

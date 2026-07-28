// Postcode Wars — Nakama server runtime (TypeScript). INERT until M3.
//
// This mirrors the client's ServerGateway so the swap is 1:1: each RPC here is
// the server-authoritative version of a LocalGateway method. The backend design
// doc's doctrine holds — the server owns every number; the client renders it.
//
// Nothing calls these yet: M1/M2 ship on the client-side LocalGateway. When you
// wire NakamaGateway in Godot, point it at these RPC ids.

const rpcResolveJob: nkruntime.RpcFunction = (ctx, logger, nk, payload) => {
  // TODO(M3): validate energy/nerve, roll seeded outcome server-side using the
  // same tables as systems/resolver.gd, write the ledger transactionally, return
  // the outcome for the client to animate. Never trust client-sent numbers.
  return JSON.stringify({ ok: false, reason: "server not live (M3)" });
};

const rpcTravel: nkruntime.RpcFunction = (ctx, logger, nk, payload) => {
  return JSON.stringify({ ok: false, reason: "server not live (M3)" });
};

const rpcResolveEncounter: nkruntime.RpcFunction = (ctx, logger, nk, payload) => {
  return JSON.stringify({ ok: false, reason: "server not live (M3)" });
};

const rpcClaimTimer: nkruntime.RpcFunction = (ctx, logger, nk, payload) => {
  return JSON.stringify({ ok: false, reason: "server not live (M3)" });
};

// Entry point Nakama calls on load.
function InitModule(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
): void {
  initializer.registerRpc("resolve_job", rpcResolveJob);
  initializer.registerRpc("travel", rpcTravel);
  initializer.registerRpc("resolve_encounter", rpcResolveEncounter);
  initializer.registerRpc("claim_timer", rpcClaimTimer);
  logger.info("Postcode Wars runtime registered (stub — M3).");
}

// referenced so bundlers keep it
!InitModule && InitModule;

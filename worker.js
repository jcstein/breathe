// Serves the latest release ZIP at /download and the landing page (site/) everywhere else.
// The Release workflow uploads each tagged release to the RELEASES namespace.
const RELEASE_KEY = "Breathe-macos.zip";

export default {
  async fetch(request, env) {
    if (new URL(request.url).pathname !== "/download") return env.ASSETS.fetch(request);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed\n", { status: 405, headers: { Allow: "GET, HEAD" } });
    }
    const zip = await env.RELEASES.get(RELEASE_KEY, "stream");
    if (zip === null) return new Response("No release has been published yet.\n", { status: 404 });
    return new Response(request.method === "HEAD" ? null : zip, {
      headers: {
        "Content-Type": "application/zip",
        "Content-Disposition": `attachment; filename="${RELEASE_KEY}"`,
        "Cache-Control": "no-cache",
      },
    });
  },
};

#!/usr/bin/env bun

// Dev server script for Hero Models TypeScript client

import { serve } from "bun";

const server = serve({
  port: 3000,
  fetch(req) {
    const url = new URL(req.url);
    
    // Serve static files
    if (url.pathname === "/" || url.pathname === "/index.html") {
      return new Response(Bun.file("index.html"));
    }
    
    // Serve TypeScript files
    if (url.pathname.endsWith(".ts")) {
      return new Response(Bun.file(url.pathname.slice(1)));
    }
    
    // Serve JavaScript files (compiled TypeScript)
    if (url.pathname.endsWith(".js")) {
      return new Response(Bun.file(url.pathname.slice(1)));
    }
    
    return new Response("Not found", { status: 404 });
  },
});

console.log(`Dev server running on http://localhost:${server.port}`);
console.log("Press Ctrl+C to stop the server");
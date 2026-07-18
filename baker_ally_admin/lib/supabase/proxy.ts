import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

const PUBLIC_PATHS = ["/login"];

// Runs on every request (see proxy.ts matcher). Refreshes the session cookie
// and gates access by role -- this is the first line of defense; the
// (dashboard) layout re-checks server-side as a second (see 6.2 plan).
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) => supabaseResponse.cookies.set(name, value, options));
        },
      },
    },
  );

  // Do not run code between createServerClient and getClaims() -- see
  // Supabase's own warning, a mistake here silently logs users out at random.
  const { data } = await supabase.auth.getClaims();
  const role = data?.claims?.app_metadata?.role as string | undefined;
  const isPublicPath = PUBLIC_PATHS.includes(request.nextUrl.pathname);

  if (!data?.claims && !isPublicPath) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  if (data?.claims && role !== "admin" && role !== "staff" && request.nextUrl.pathname !== "/unauthorized") {
    const url = request.nextUrl.clone();
    url.pathname = "/unauthorized";
    return NextResponse.redirect(url);
  }

  if (data?.claims && (role === "admin" || role === "staff") && isPublicPath) {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}

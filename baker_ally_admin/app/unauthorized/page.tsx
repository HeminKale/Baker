import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { SignOutButton } from "@/components/sign-out-button";

export default async function UnauthorizedPage() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();

  // No session at all -- nothing to explain, just send them to log in.
  if (!data?.claims) {
    redirect("/login");
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-4 text-center">
      <h1 className="text-xl font-semibold">Not authorized</h1>
      <p className="max-w-sm text-sm text-muted-foreground">
        Your account doesn&apos;t have admin or staff access to the Baker Ally panel. Contact an
        admin if you believe this is a mistake.
      </p>
      <SignOutButton />
    </div>
  );
}

import { requireUser } from "@/lib/auth";

export default async function DashboardPage() {
  const me = await requireUser();

  return (
    <div>
      <h1 className="text-2xl font-semibold">Welcome{me.user.fullName ? `, ${me.user.fullName}` : ""}</h1>
      <p className="text-muted-foreground">
        Signed in as {me.user.email ?? me.user.phone} ({me.role}).
      </p>
    </div>
  );
}

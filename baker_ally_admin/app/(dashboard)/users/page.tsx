import { requireAdmin } from "@/lib/auth";
import { apiFetch } from "@/lib/api";
import type { AdminOrStaffUser } from "@/lib/types";
import { UsersManager } from "./users-client";

export default async function UsersPage() {
  await requireAdmin();
  const res = await apiFetch<{ data: AdminOrStaffUser[] }>("/v1/admin/users");

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Users</h1>
      </div>
      <UsersManager initialUsers={res.data} />
    </div>
  );
}

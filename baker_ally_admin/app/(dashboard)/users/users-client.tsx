"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { apiFetchClient, ApiError } from "@/lib/api-client";
import type { AdminOrStaffUser } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

type Role = "admin" | "staff";

export function UsersManager({ initialUsers }: { initialUsers: AdminOrStaffUser[] }) {
  const router = useRouter();
  const [inviteOpen, setInviteOpen] = useState(false);
  const [changingRoleFor, setChangingRoleFor] = useState<AdminOrStaffUser | null>(null);

  async function handleRoleChange(userId: string, role: Role) {
    try {
      await apiFetchClient(`/v1/admin/users/${userId}/role`, {
        method: "PATCH",
        body: JSON.stringify({ role }),
      });
      toast.success("Role updated -- takes effect on their next sign-in");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setChangingRoleFor(null);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-end">
        <Button onClick={() => setInviteOpen(true)}>Invite user</Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Role</TableHead>
            <TableHead className="w-1" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {initialUsers.map((u) => (
            <TableRow key={u.id}>
              <TableCell>{u.fullName ?? "-"}</TableCell>
              <TableCell>{u.email}</TableCell>
              <TableCell>
                <Badge variant={u.role === "admin" ? "default" : "secondary"} className="capitalize">
                  {u.role}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="sm" onClick={() => setChangingRoleFor(u)}>
                  Change role
                </Button>
              </TableCell>
            </TableRow>
          ))}
          {initialUsers.length === 0 && (
            <TableRow>
              <TableCell colSpan={4} className="text-center text-muted-foreground">
                No admin/staff users yet
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      {inviteOpen && <InviteDialog onClose={() => setInviteOpen(false)} />}

      {changingRoleFor && (
        <RoleDialog
          user={changingRoleFor}
          onClose={() => setChangingRoleFor(null)}
          onSave={(role) => handleRoleChange(changingRoleFor.id, role)}
        />
      )}
    </div>
  );
}

function RoleDialog({
  user,
  onClose,
  onSave,
}: {
  user: AdminOrStaffUser;
  onClose: () => void;
  onSave: (role: Role) => void;
}) {
  const [role, setRole] = useState<Role>(user.role);

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Change role for {user.email}</DialogTitle>
        </DialogHeader>
        <Select value={role} onValueChange={(v) => setRole(v as Role)}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="staff">Staff</SelectItem>
          </SelectContent>
        </Select>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={() => onSave(role)} disabled={role === user.role}>
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function InviteDialog({ onClose }: { onClose: () => void }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<Role>("staff");
  const [saving, setSaving] = useState(false);
  const [actionLink, setActionLink] = useState<string | null>(null);

  async function handleInvite() {
    setSaving(true);
    try {
      const res = await apiFetchClient<{ data: { actionLink: string } }>("/v1/admin/users/invite", {
        method: "POST",
        body: JSON.stringify({ email, role }),
      });
      setActionLink(res.data.actionLink);
      toast.success("User created -- send them the link below");
      router.refresh();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  function handleClose() {
    setActionLink(null);
    onClose();
  }

  return (
    <Dialog open onOpenChange={(open) => !open && handleClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Invite a user</DialogTitle>
        </DialogHeader>

        {actionLink ? (
          <div className="flex flex-col gap-3">
            <p className="text-sm text-muted-foreground">
              No email provider is configured yet -- copy this link and send it to them manually. It lets them
              set their password.
            </p>
            <Input readOnly value={actionLink} onFocus={(e) => e.currentTarget.select()} />
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="invite-email">Email</Label>
              <Input id="invite-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="invite-role">Role</Label>
              <Select value={role} onValueChange={(v) => setRole(v as Role)}>
                <SelectTrigger id="invite-role">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="admin">Admin</SelectItem>
                  <SelectItem value="staff">Staff</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        )}

        <DialogFooter>
          <Button variant="outline" onClick={handleClose}>
            {actionLink ? "Done" : "Cancel"}
          </Button>
          {!actionLink && (
            <Button onClick={handleInvite} disabled={saving || !email.trim()}>
              {saving ? "Inviting..." : "Invite"}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

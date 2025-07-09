import { useMutation } from "@tanstack/solid-query";
import { createFileRoute, Link } from "@tanstack/solid-router";
import { For } from "solid-js";

export const Route = createFileRoute("/admin/users/")({
  component: RouteComponent,
  loader: ({ context: { api, query } }) =>
    query.ensureQueryData(api.users.list),
});

function RouteComponent() {
  const users = Route.useLoaderData();
  const context = Route.useRouteContext();

  const deleteMutation = useMutation(() => ({
    ...context().api.users.remove,
    onSuccess: () => {
      context().query.invalidateQueries({ queryKey: ["users"] });
    },
  }));

  const handleDelete = (id: string, name: string) => {
    if (window.confirm(`Are you sure you want to delete user "${name}"?`)) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div>
      <h1>Users</h1>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>First Name</th>
            <th>Last Name</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <For each={users()}>
            {(user) => (
              <tr>
                <td>{user.id}</td>
                <td>{user.first_name}</td>
                <td>{user.last_name}</td>
                <td>
                  <Link to="/admin/users/$id" params={{ id: user.id }}>
                    <button type="button">Edit</button>
                  </Link>
                  <button
                    type="button"
                    onClick={() =>
                      handleDelete(
                        user.id,
                        `${user.first_name} ${user.last_name}`,
                      )
                    }
                    disabled={deleteMutation.isPending}
                  >
                    {deleteMutation.isPending ? "Deleting..." : "Delete"}
                  </button>
                </td>
              </tr>
            )}
          </For>
        </tbody>
      </table>
    </div>
  );
}

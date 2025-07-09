import { useMutation } from "@tanstack/solid-query";
import { createFileRoute, Link } from "@tanstack/solid-router";
import { For } from "solid-js";

export const Route = createFileRoute("/admin/sessions/")({
  component: RouteComponent,
  loader: ({ context: { api, query } }) =>
    query.ensureQueryData(api.sessions.list),
});

function RouteComponent() {
  const sessions = Route.useLoaderData();
  const context = Route.useRouteContext();

  const deleteMutation = useMutation(() => ({
    ...context().api.sessions.remove,
    onSuccess: () => {
      context().query.invalidateQueries({ queryKey: ["sessions"] });
    },
  }));

  const handleDelete = (id: string, name: string) => {
    if (window.confirm(`Are you sure you want to delete session "${name}"?`)) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div>
      <h1>Sessions</h1>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <For each={sessions()}>
            {(session) => (
              <tr>
                <td>{session.id}</td>
                <td>{session.name}</td>
                <td>
                  <Link to="/admin/sessions/$id" params={{ id: session.id }}>
                    <button type="button">Edit</button>
                  </Link>
                  <button
                    type="button"
                    onClick={() => handleDelete(session.id, session.name)}
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

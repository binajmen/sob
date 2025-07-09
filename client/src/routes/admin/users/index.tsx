import { createFileRoute } from "@tanstack/solid-router";
import { For } from "solid-js";

export const Route = createFileRoute("/admin/users/")({
  component: RouteComponent,
  loader: ({ context: { api, query } }) =>
    query.ensureQueryData(api.users.list),
});

function RouteComponent() {
  const users = Route.useLoaderData();

  return (
    <div>
      <h1>Users</h1>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>First Name</th>
            <th>Last Name</th>
          </tr>
        </thead>
        <tbody>
          <For each={users()}>
            {(user) => (
              <tr>
                <td>{user.id}</td>
                <td>{user.first_name}</td>
                <td>{user.last_name}</td>
              </tr>
            )}
          </For>
        </tbody>
      </table>
    </div>
  );
}

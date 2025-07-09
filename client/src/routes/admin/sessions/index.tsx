import { createFileRoute } from '@tanstack/solid-router'
import { For } from "solid-js";

export const Route = createFileRoute('/admin/sessions/')({
  component: RouteComponent,
  loader: ({ context: { api, query } }) =>
    query.ensureQueryData(api.sessions.list),
})

function RouteComponent() {
  const sessions = Route.useLoaderData();
  
  return (
    <div>
      <h1>Sessions</h1>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
          </tr>
        </thead>
        <tbody>
          <For each={sessions()}>
            {(session) => (
              <tr>
                <td>{session.id}</td>
                <td>{session.name}</td>
              </tr>
            )}
          </For>
        </tbody>
      </table>
    </div>
  );
}

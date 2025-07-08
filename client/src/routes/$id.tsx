import { createFileRoute } from "@tanstack/solid-router";

export const Route = createFileRoute("/$id")({
  component: RouteComponent,
  loader: ({ context: { api, query } }) =>
    query.ensureQueryData(api.questions.list),
});

function RouteComponent() {
  return <div>Hello "/$id"!</div>;
}

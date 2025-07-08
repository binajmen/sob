import { createFileRoute } from "@tanstack/solid-router";

export const Route = createFileRoute("/")({
  component: Index,
});

function Index() {
  return (
    <div class="p-2">
      <h1>Vote</h1>
    </div>
  );
}

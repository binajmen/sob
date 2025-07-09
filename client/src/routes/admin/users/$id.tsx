import { useMutation } from "@tanstack/solid-query";
import { createFileRoute, useNavigate } from "@tanstack/solid-router";
import { createSignal, Show } from "solid-js";

export const Route = createFileRoute("/admin/users/$id")({
  component: RouteComponent,
  loader: ({ context: { api, query }, params }) =>
    query.ensureQueryData(api.users.find(params.id)),
});

function RouteComponent() {
  const user = Route.useLoaderData();
  const context = Route.useRouteContext();
  const navigate = useNavigate();

  const [firstName, setFirstName] = createSignal("");
  const [lastName, setLastName] = createSignal("");

  const updateMutation = useMutation(() => ({
    ...context().api.users.update,
    onSuccess: () => {
      context().query.invalidateQueries({ queryKey: ["users"] });
      navigate({ to: "/admin/users" });
    },
  }));

  const handleSubmit = (e: Event) => {
    e.preventDefault();
    updateMutation.mutate({
      id: user().id,
      first_name: firstName() || user().first_name,
      last_name: lastName() || user().last_name,
    });
  };

  return (
    <div>
      <h1>Edit User</h1>

      <form onSubmit={handleSubmit}>
        <div>
          <label for="firstName">First Name:</label>
          <br />
          <input
            type="text"
            id="firstName"
            name="firstName"
            value={firstName() || user().first_name}
            onInput={(e) => setFirstName(e.target.value)}
            required
          />
        </div>

        <div>
          <label for="lastName">Last Name:</label>
          <br />
          <input
            type="text"
            id="lastName"
            name="lastName"
            value={lastName() || user().last_name}
            onInput={(e) => setLastName(e.target.value)}
            required
          />
        </div>

        <div>
          <button type="submit" disabled={updateMutation.isPending}>
            {updateMutation.isPending ? "Updating..." : "Update User"}
          </button>

          <button
            type="button"
            onClick={() => navigate({ to: "/admin/users" })}
          >
            Cancel
          </button>
        </div>

        <Show when={updateMutation.error}>
          <p>Error: {updateMutation.error?.message}</p>
        </Show>
      </form>
    </div>
  );
}

import { createForm } from "@tanstack/solid-form";
import { useMutation } from "@tanstack/solid-query";
import { createFileRoute, useNavigate } from "@tanstack/solid-router";
import { Show } from "solid-js";

export const Route = createFileRoute("/admin/sessions/$id")({
  component: RouteComponent,
  loader: ({ context: { api, query }, params }) =>
    query.ensureQueryData(api.sessions.find(params.id)),
});

function RouteComponent() {
  const session = Route.useLoaderData();
  const context = Route.useRouteContext();
  const navigate = useNavigate();

  const updateMutation = useMutation(() => ({
    ...context().api.sessions.update,
    onSuccess: () => {
      context().query.invalidateQueries({ queryKey: ["sessions"] });
      navigate({ to: "/admin/sessions" });
    },
  }));

  const form = createForm(() => ({
    defaultValues: {
      name: session().name,
    },
    onSubmit: async ({ value }) => {
      updateMutation.mutate({
        id: session().id,
        name: value.name,
      });
    },
  }));

  return (
    <div>
      <h1>Edit Session</h1>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          e.stopPropagation();
          form.handleSubmit();
        }}
      >
        <div>
          <form.Field name="name">
            {(field) => (
              <>
                <label for="name">Name:</label>
                <br />
                <input
                  type="text"
                  id="name"
                  name={field().name}
                  value={field().state.value}
                  onBlur={field().handleBlur}
                  onInput={(e) => field().handleChange(e.target.value)}
                  required
                />
              </>
            )}
          </form.Field>
        </div>

        <div>
          <button type="submit" disabled={updateMutation.isPending}>
            {updateMutation.isPending ? "Updating..." : "Update Session"}
          </button>

          <button
            type="button"
            onClick={() => navigate({ to: "/admin/sessions" })}
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

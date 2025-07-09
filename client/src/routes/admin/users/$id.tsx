import { useMutation } from "@tanstack/solid-query";
import { createFileRoute, useNavigate } from "@tanstack/solid-router";
import { Show } from "solid-js";
import { useAppForm } from "~/hooks/form";

export const Route = createFileRoute("/admin/users/$id")({
  component: RouteComponent,
  loader: ({ context: { api, query }, params }) =>
    query.ensureQueryData(api.users.find(params.id)),
});

function RouteComponent() {
  const user = Route.useLoaderData();
  const context = Route.useRouteContext();
  const navigate = useNavigate();

  const updateMutation = useMutation(() => ({
    ...context().api.users.update,
    onSuccess: () => {
      context().query.invalidateQueries({ queryKey: ["users"] });
      navigate({ to: "/admin/users" });
    },
  }));

  const form = useAppForm(() => ({
    defaultValues: {
      first_name: user().first_name,
      last_name: user().last_name,
    },
    onSubmit: async ({ value }) => {
      updateMutation.mutate({
        id: user().id,
        first_name: value.first_name,
        last_name: value.last_name,
      });
    },
  }));

  return (
    <div>
      <h1>Edit User</h1>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          e.stopPropagation();
          form.handleSubmit();
        }}
      >
        <form.AppField name="first_name">
          {(field) => <field.TextField label="Fist name" />}
        </form.AppField>

        <form.AppField name="last_name">
          {(field) => <field.TextField label="Last name" />}
        </form.AppField>

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

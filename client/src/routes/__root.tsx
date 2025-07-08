import type { QueryClient } from "@tanstack/solid-query";
import { createRootRouteWithContext, Outlet } from "@tanstack/solid-router";
import { TanStackRouterDevtools } from "@tanstack/solid-router-devtools";
import type { Api } from "~/api";

export const Route = createRootRouteWithContext<{
  api: Api;
  query: QueryClient;
}>()({
  component: () => {
    return (
      <>
        <Outlet />
        <TanStackRouterDevtools />
      </>
    );
  },
  notFoundComponent: () => <div>404 Not Found</div>,
});

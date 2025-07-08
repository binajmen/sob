import { createRouter, RouterProvider } from "@tanstack/solid-router";
import { render } from "solid-js/web";
import "./index.css";
import { QueryClient, QueryClientProvider } from "@tanstack/solid-query";
import { api } from "./api";
import { routeTree } from "./routeTree.gen";

const queryClient = new QueryClient();

const router = createRouter({
  routeTree,
  // Since we're using React Query, we don't want loader calls to ever be stale
  // This will ensure that the loader is always called when the route is preloaded or visited
  defaultPreloadStaleTime: 0,
  scrollRestoration: true,
  context: {
    api,
    query: queryClient,
  },
});

declare module "@tanstack/solid-router" {
  interface Register {
    router: typeof router;
  }
}

const rootElement = document.getElementById("root")!;
if (!rootElement.innerHTML) {
  render(
    () => (
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    ),
    rootElement,
  );
}

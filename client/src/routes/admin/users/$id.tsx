import { createFileRoute } from '@tanstack/solid-router'

export const Route = createFileRoute('/admin/users/$id')({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello "/admin/users/$id"!</div>
}

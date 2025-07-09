import { createFileRoute } from '@tanstack/solid-router'

export const Route = createFileRoute('/admin/sessions/$id')({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello "/admin/sessions/$id"!</div>
}

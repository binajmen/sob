import { type MutationOptions, queryOptions } from "@tanstack/solid-query";
import * as z from "zod/v4";
import { del, get, post } from "~/api";

const userSchema = z.object({
  id: z.string(),
  first_name: z.string(),
  last_name: z.string(),
});

type User = z.infer<typeof userSchema>;
type NewUser = Omit<User, "id">;

const list = queryOptions({
  queryKey: ["users"],
  queryFn: () => get("/users", z.array(userSchema)),
});

const find = (id: string) =>
  queryOptions({
    queryKey: ["users", id],
    queryFn: () => get(`/users/${id}`, userSchema),
  });

const create = {
  mutationFn: (user: NewUser) => post("/users", user, userSchema),
} satisfies MutationOptions<User, Error, NewUser>;

const update = {
  mutationFn: (user: User) => post(`/users/${user.id}`, user, userSchema),
} satisfies MutationOptions<User, Error, User>;

const remove = {
  mutationFn: (id: string) => del(`/users/${id}`),
} satisfies MutationOptions<void, Error, string>;

export const users = {
  list,
  find,
  create,
  update,
  remove,
};


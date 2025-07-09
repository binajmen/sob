import { type MutationOptions, queryOptions } from "@tanstack/solid-query";
import * as z from "zod/v4";
import { get, post } from "~/api";

const sessionSchema = z.object({
  id: z.string(),
  name: z.string(),
});

type Session = z.infer<typeof sessionSchema>;
type NewSession = Omit<Session, "id">;

const list = queryOptions({
  queryKey: ["sessions"],
  queryFn: () => get("/sessions", z.array(sessionSchema)),
});

const find = (id: string) =>
  queryOptions({
    queryKey: ["sessions", id],
    queryFn: () => get(`/sessions/${id}`, sessionSchema),
  });

const create = {
  mutationFn: (session: NewSession) =>
    post("/sessions", session, sessionSchema),
} satisfies MutationOptions<Session, Error, NewSession>;

const update = {
  mutationFn: (session: Session) =>
    post(`/sessions/${session.id}`, session, sessionSchema),
} satisfies MutationOptions<Session, Error, Session>;

export const sessions = {
  list,
  find,
  create,
  update,
};


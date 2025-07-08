import type * as z from "zod/v4";
import { questions } from "~/api/questions";

export const API_URL = "http://localhost:8010";

export async function get<Schema extends z.ZodSchema>(
  path: string,
  schema: Schema,
): Promise<z.infer<Schema>> {
  const headers: HeadersInit = {};

  return fetch(`${API_URL}${path}`, { headers })
    .then((res) => res.json())
    .then((json) => schema.parse(json));
}

export async function post<Schema extends z.ZodSchema>(
  path: string,
  values: unknown,
  schema: Schema,
): Promise<z.infer<Schema>> {
  const headers: HeadersInit = { "content-type": "application/json" };

  return fetch(`${API_URL}${path}`, {
    method: "post",
    headers,
    body: JSON.stringify(values),
  })
    .then((res) => res.json())
    .then((json) => schema.parse(json));
}

export const api = {
  questions,
};

export type Api = typeof api;

import { type MutationOptions, queryOptions } from "@tanstack/solid-query";
import * as z from "zod/v4";
import { get, post } from "~/api";

const questionSchema = z.object({
  id: z.string(),
  text: z.string(),
});

type Question = z.infer<typeof questionSchema>;
type NewQuestion = Omit<Question, "id">;

const list = queryOptions({
  queryKey: ["questions"],
  queryFn: () => get("/questions", z.array(questionSchema)),
});

const find = (id: string) =>
  queryOptions({
    queryKey: ["questions", id],
    queryFn: () => get(`/questions/${id}`, questionSchema),
  });

const create = {
  mutationFn: (question: NewQuestion) =>
    post("/questions", question, questionSchema),
} satisfies MutationOptions<Question, Error, NewQuestion>;

const update = {
  mutationFn: (question: Question) =>
    post(`/questions/${question.id}`, question, questionSchema),
} satisfies MutationOptions<Question, Error, Question>;

export const questions = {
  list,
  find,
  create,
  update,
};

import { createFormHook, createFormHookContexts } from "@tanstack/solid-form";
import { lazy } from "solid-js";

export const { fieldContext, useFieldContext, formContext, useFormContext } =
  createFormHookContexts();

const TextField = lazy(() => import("~/components/text-field"));
const SubmitButton = lazy(() => import("~/components/submit-button"));

export const { useAppForm, withForm } = createFormHook({
  fieldComponents: {
    TextField,
  },
  formComponents: {
    SubmitButton,
  },
  fieldContext,
  formContext,
});

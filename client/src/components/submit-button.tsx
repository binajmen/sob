import { useFormContext } from "~/hooks/form";

export default function SubmitButton(props: { label: string }) {
  const form = useFormContext();

  return (
    <form.Subscribe selector={(state) => state.isSubmitting}>
      {(isSubmitting) => (
        <button type="submit" disabled={isSubmitting()}>
          {props.label}
        </button>
      )}
    </form.Subscribe>
  );
}

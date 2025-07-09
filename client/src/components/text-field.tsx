import { useStore } from "@tanstack/solid-form";
import { type ComponentProps, For } from "solid-js";
import { useFieldContext } from "~/hooks/form";

interface TextFieldProps extends ComponentProps<"input"> {
  label: string;
}

export default function TextField(props: TextFieldProps) {
  const field = useFieldContext<string>();
  const errors = useStore(field().store, (state) => state.meta.errors);

  return (
    <div>
      <label>
        <div>{props.label}</div>
        <input
          {...props}
          name={field().name}
          value={field().state.value}
          onBlur={field().handleBlur}
          onInput={(e) => field().handleChange(e.target.value)}
          onChange={(e) => field().handleChange(e.target.value)}
        />
      </label>
      <For each={errors()}>
        {(error) => <div style={{ color: "red" }}>{error}</div>}
      </For>
    </div>
  );
}

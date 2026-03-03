# Object::Pad mutator debugger note

Some debuggers can trip on lvalue-style mutator assignments during single-step operations.

## Preferred coding rule

- Keep normal runtime code idiomatic (`$obj->field = $value` for `:mutator` fields).
- Do not introduce ad-hoc setter methods only to bypass debugger behavior.

## If debugger stepping is blocked

- Prefer stepping over (`n`) the assignment site.
- For temporary local debugging only, use explicit mutator call style (`$obj->field($value)`) if needed.
- Do not widen workaround changes across unrelated modules.

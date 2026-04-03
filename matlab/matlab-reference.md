# MATLAB Reference — Beginner & Intermediate

Quick-reference for introductory MATLAB coursework. Compiled from MathWorks documentation.

---

## Reserved Keywords

These 20 identifiers are returned by `iskeyword` in MATLAB. They cannot be used as
variable names, function names, or any other user-defined identifier.

| Keyword | Category | Description |
|---------|----------|-------------|
| `break` | Loop control | Exits the innermost `for` or `while` loop immediately; execution resumes at the statement after the loop's `end` |
| `case` | Branching | Defines a branch condition within a `switch` block; executes its body when the `switch` expression matches |
| `catch` | Error handling | Defines the error-handling block in a `try`/`catch` statement; receives control when an error is thrown in the `try` block |
| `classdef` | OOP | Opens a class definition block in a class definition file; used to define properties, methods, and events for a MATLAB class |
| `continue` | Loop control | Skips the remainder of the current loop iteration and proceeds to the next iteration of the enclosing `for` or `while` loop |
| `else` | Branching | Provides a fallback branch in an `if` statement; its body executes when no preceding `if` or `elseif` condition is true |
| `elseif` | Branching | Adds an additional conditional branch to an `if` statement; evaluated only if all preceding conditions are false |
| `end` | Block terminator | Terminates a `for`, `while`, `if`, `switch`, `try`, `parfor`, `spmd`, `function`, `classdef`, or `methods`/`properties` block; also used as the last-index shorthand in array indexing (e.g., `A(end)`) |
| `for` | Loop | Executes a block of statements a fixed number of times by iterating a loop variable over a specified range or array |
| `function` | Function definition | Declares the start of a function definition; specifies the function name, input arguments, and output arguments |
| `global` | Variable scope | Declares one or more variables as global, making them accessible across multiple functions and the base workspace without passing them as arguments |
| `if` | Branching | Evaluates a logical condition and executes its body only when the condition is true (nonzero) |
| `otherwise` | Branching | Provides the default branch in a `switch` block; its body executes when no `case` expression matches the `switch` expression |
| `parfor` | Parallel loop | Parallel `for`-loop (requires Parallel Computing Toolbox); iterations execute on parallel workers; each iteration must be independent of all others |
| `persistent` | Variable scope | Declares a variable local to a function that retains its value between calls to that function; initialized only the first time the function runs |
| `return` | Flow control | Causes execution to immediately return to the invoking function or the base workspace, before the end of the current function body is reached |
| `spmd` | Parallel block | Single Program Multiple Data block (requires Parallel Computing Toolbox); runs identical code simultaneously on multiple workers, each with its own independent data |
| `switch` | Branching | Evaluates an expression and transfers control to the `case` block whose value matches; replaces long `if`/`elseif` chains when comparing one value against many |
| `try` | Error handling | Opens a protected block of code; if any statement inside throws an error, control passes to the `catch` block instead of aborting execution |
| `while` | Loop | Repeatedly executes a block of statements as long as a specified logical condition remains true |

---

## Operators

### Arithmetic Operators

MATLAB distinguishes **matrix operations** (linear algebra rules) from **element-wise array
operations** (applied independently to each element, indicated by a leading `.`). Addition
and subtraction are inherently element-wise, so no dot form exists for them.

| Operator | Name | Description |
|----------|------|-------------|
| `+` | Addition | Adds two arrays element-by-element, or adds a scalar to every element of an array |
| `-` | Subtraction | Subtracts one array from another element-by-element, or subtracts a scalar from every element |
| `*` | Matrix multiplication | Multiplies two matrices following linear algebra rules; inner dimensions must agree |
| `.*` | Element-wise multiplication | Multiplies corresponding elements of two arrays of the same size |
| `/` | Matrix right division | `A/B` solves `X*B = A`; for scalars this is ordinary division |
| `./` | Element-wise right division | Divides each element of `A` by the corresponding element of `B` |
| `\` | Matrix left division | `A\B` solves `A*X = B`; used for linear systems; for scalars equivalent to `B/A` |
| `.\` | Element-wise left division | Divides each element of `B` by the corresponding element of `A` (i.e., `B./A`) |
| `^` | Matrix power | Raises a square matrix to an integer or scalar power using matrix exponentiation |
| `.^` | Element-wise power | Raises each element of an array to the corresponding power in another array or to a scalar power |
| `'` | Complex conjugate transpose | Transposes a matrix and conjugates every element; for real matrices equivalent to `.'` |
| `.'` | Array transpose | Transposes a matrix without conjugating complex elements; swaps rows and columns |

### Relational Operators

Relational operators compare arrays element-by-element and return a logical array of the
same size with `1` (true) where the condition holds and `0` (false) where it does not.

| Operator | Name | Description |
|----------|------|-------------|
| `==` | Equal to | Returns `1` for each position where corresponding elements are equal |
| `~=` | Not equal to | Returns `1` for each position where corresponding elements are not equal |
| `>` | Greater than | Returns `1` where the left element is strictly greater than the right element |
| `<` | Less than | Returns `1` where the left element is strictly less than the right element |
| `>=` | Greater than or equal to | Returns `1` where the left element is greater than or equal to the right element |
| `<=` | Less than or equal to | Returns `1` where the left element is less than or equal to the right element |

### Logical Operators

MATLAB provides two sets of logical operators: **element-wise** operators that work on
arrays, and **short-circuit** operators that work only on scalar logical values and stop
evaluating as soon as the result is determined.

| Operator | Name | Description |
|----------|------|-------------|
| `&` | Element-wise AND | Returns `1` where both corresponding elements of two logical arrays are true; evaluates both operands |
| `\|` | Element-wise OR | Returns `1` where at least one corresponding element is true; evaluates both operands |
| `~` | Logical NOT | Inverts each element of a logical array; `~true` is `false`, `~false` is `true` |
| `&&` | Short-circuit AND | Evaluates left operand first; skips right operand if left is false; scalars only; preferred in `if`/`while` conditions |
| `\|\|` | Short-circuit OR | Evaluates left operand first; skips right operand if left is true; scalars only; preferred in `if`/`while` conditions |

### Special Characters

| Character | Name | Description |
|-----------|------|-------------|
| `:` | Colon | Creates regularly spaced vectors (`start:step:stop`); used in `for` loop ranges; indexes entire rows/columns (`A(:,2)`); with no bounds selects all elements |
| `;` | Semicolon | Suppresses command output when placed at the end of a statement; also separates rows in array literals (`[1 2; 3 4]`); separates multiple statements on one line |
| `,` | Comma | Separates elements within a row of an array literal; separates function arguments and return values; separates multiple statements on one line (output is shown) |
| `()` | Parentheses | Enclose function call arguments (`sin(x)`); index into arrays and matrices using one-based indexing (`A(2,3)`); override operator precedence in expressions |
| `[]` | Square brackets | Construct arrays and matrices by enclosing a list of elements (`[1 2 3]`); concatenate arrays horizontally (space/comma) or vertically (semicolon); also used on the left side of assignment to capture multiple return values (`[a,b] = size(M)`) |
| `{}` | Curly braces | Construct cell arrays (`{1, 'hello', true}`); index into cell arrays to retrieve cell contents (`C{2}`); required whenever the contents are of different types |
| `.` | Dot | Decimal point in numeric literals (`3.14`); accesses fields of a structure (`s.name`); prefix for element-wise operators (`.*, ./, .^, .'`); separates package names from class or function names |
| `...` | Ellipsis | Line continuation operator; three consecutive periods tell MATLAB to treat the next line as a continuation of the current statement; anything after `...` on the same line is ignored as a comment |
| `@` | At sign | Creates a function handle to a named function (`f = @sin`) or an anonymous function (`f = @(x) x.^2 + 1`); the handle can be stored, passed to other functions, or called later |
| `%` | Percent | Begins an inline comment; everything from `%` to the end of the line is ignored by the interpreter; `%%` creates a cell break in the Editor and starts a code section |

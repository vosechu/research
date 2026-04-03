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

---

## Core Function Library

### Math Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `abs` | `Y = abs(X)` | Absolute value of each element; for complex numbers returns the magnitude |
| `ceil` | `Y = ceil(X)` | Round each element toward positive infinity to the nearest integer |
| `floor` | `Y = floor(X)` | Round each element toward negative infinity to the nearest integer |
| `round` | `Y = round(X)` | Round each element to the nearest integer; ties round away from zero |
| `mod` | `r = mod(a, m)` | Modulus after division; result has the same sign as the divisor `m` |
| `rem` | `r = rem(a, b)` | Remainder after division; result has the same sign as the dividend `a` |
| `sqrt` | `Y = sqrt(X)` | Square root of each element; returns complex values for negative inputs |
| `exp` | `Y = exp(X)` | Natural exponential `e^X` for each element |
| `log` | `Y = log(X)` | Natural logarithm (base `e`) of each element |
| `log2` | `Y = log2(X)` | Base-2 logarithm of each element |
| `log10` | `Y = log10(X)` | Base-10 (common) logarithm of each element |
| `sin` | `Y = sin(X)` | Sine of each element, with `X` in radians |
| `cos` | `Y = cos(X)` | Cosine of each element, with `X` in radians |
| `tan` | `Y = tan(X)` | Tangent of each element, with `X` in radians |
| `max` | `m = max(A)` or `[m,i] = max(A)` or `m = max(A,B)` | Largest element of an array; optionally returns the index; or element-wise maximum of two arrays |
| `min` | `m = min(A)` or `[m,i] = min(A)` or `m = min(A,B)` | Smallest element of an array; optionally returns the index; or element-wise minimum of two arrays |
| `sum` | `S = sum(A)` or `S = sum(A,dim)` | Sum of elements along a dimension (default: first non-singleton dimension) |
| `prod` | `P = prod(A)` or `P = prod(A,dim)` | Product of elements along a dimension (default: first non-singleton dimension) |
| `mean` | `M = mean(A)` or `M = mean(A,dim)` | Arithmetic mean of elements along a dimension |
| `median` | `M = median(A)` or `M = median(A,dim)` | Median value of elements along a dimension |
| `std` | `s = std(A)` or `s = std(A,w,dim)` | Standard deviation; `w=0` normalizes by N-1 (default), `w=1` by N |
| `cumsum` | `B = cumsum(A)` or `B = cumsum(A,dim)` | Cumulative sum of elements along a dimension |
| `diff` | `Y = diff(X)` or `Y = diff(X,n)` or `Y = diff(X,n,dim)` | Differences between consecutive elements; `n` specifies order; reduces length by 1 per order |

### Array / Matrix Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `zeros` | `A = zeros(n)` or `A = zeros(m,n)` or `A = zeros(sz)` | Create an array of all zeros with the specified dimensions |
| `ones` | `A = ones(n)` or `A = ones(m,n)` or `A = ones(sz)` | Create an array of all ones with the specified dimensions |
| `eye` | `I = eye(n)` or `I = eye(m,n)` | Create an identity matrix of size n-by-n or m-by-n |
| `rand` | `A = rand(n)` or `A = rand(m,n)` | Uniformly distributed pseudorandom numbers in (0, 1) |
| `randn` | `A = randn(n)` or `A = randn(m,n)` | Standard normally distributed pseudorandom numbers (mean 0, variance 1) |
| `linspace` | `v = linspace(x1,x2,n)` | Generate `n` linearly spaced points between `x1` and `x2` inclusive |
| `logspace` | `v = logspace(a,b,n)` | Generate `n` logarithmically spaced points between `10^a` and `10^b` |
| `size` | `sz = size(A)` or `[m,n] = size(A)` or `d = size(A,dim)` | Return the dimensions of an array as a row vector, or a specific dimension's length |
| `length` | `n = length(A)` | Return the length of the largest array dimension |
| `numel` | `n = numel(A)` | Return the total number of elements in an array |
| `reshape` | `B = reshape(A,m,n)` or `B = reshape(A,sz)` | Reshape array to specified dimensions without changing element count |
| `transpose` | `B = transpose(A)` | Non-conjugate transpose; equivalent to `A.'` |
| `inv` | `B = inv(A)` | Inverse of a square matrix; use `A\b` instead for solving linear systems |
| `det` | `d = det(A)` | Determinant of a square matrix |
| `eig` | `d = eig(A)` or `[V,D] = eig(A)` | Eigenvalues and (optionally) eigenvectors of a square matrix |
| `diag` | `v = diag(A)` or `D = diag(v)` | Extract main diagonal of a matrix, or create a diagonal matrix from a vector |
| `cat` | `C = cat(dim,A,B,...)` | Concatenate arrays along the specified dimension |
| `horzcat` | `C = horzcat(A,B,...)` | Concatenate arrays horizontally (along columns); equivalent to `[A, B]` |
| `vertcat` | `C = vertcat(A,B,...)` | Concatenate arrays vertically (along rows); equivalent to `[A; B]` |
| `repmat` | `B = repmat(A,m,n)` or `B = repmat(A,r)` | Tile an array by repeating it `m`-by-`n` (or per vector `r`) times |
| `sort` | `B = sort(A)` or `B = sort(A,dim)` or `[B,I] = sort(A,dim,direction)` | Sort array elements in ascending or descending order; optionally return sort indices |
| `find` | `idx = find(X)` or `[row,col] = find(X)` | Indices of nonzero (true) elements; optionally returns row and column subscripts |
| `unique` | `C = unique(A)` or `[C,ia,ic] = unique(A)` | Unique values of an array, sorted; optionally returns index mappings |
| `sub2ind` | `idx = sub2ind(sz,row,col)` | Convert row/column subscripts to linear indices for an array of size `sz` |
| `ind2sub` | `[row,col] = ind2sub(sz,idx)` | Convert linear indices to row/column subscripts for an array of size `sz` |

### String Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `string` | `str = string(A)` | Convert a value to a `string` array (double-quoted string type) |
| `char` | `c = char(A)` | Convert to a character array (single-quoted, legacy char type) |
| `strcat` | `str = strcat(s1,s2,...)` | Concatenate strings; trailing whitespace is trimmed from char arrays (not string arrays) |
| `strcmp` | `tf = strcmp(s1,s2)` | Compare strings for exact equality; case-sensitive; returns logical scalar or array |
| `strcmpi` | `tf = strcmpi(s1,s2)` | Compare strings for equality, ignoring case |
| `contains` | `tf = contains(str,pattern)` | Return true if `str` contains the specified substring or pattern |
| `strsplit` | `C = strsplit(str)` or `C = strsplit(str,delimiter)` | Split a string at whitespace or a specified delimiter; returns a cell array of strings |
| `strtrim` | `str = strtrim(str)` | Remove leading and trailing whitespace from a string |
| `num2str` | `str = num2str(A)` or `str = num2str(A,format)` | Convert a number to a character array representation |
| `str2num` | `X = str2num(str)` | Convert a character array to a numeric value; returns empty if conversion fails |
| `sprintf` | `str = sprintf(format,A,...)` | Format data into a string using C-style format specifiers; returns a string |
| `fprintf` | `fprintf(format,A,...)` or `fprintf(fileID,format,A,...)` | Print formatted data to the command window or to a file |

### Plotting Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `plot` | `plot(X,Y)` or `plot(X,Y,LineSpec)` | Create a 2-D line plot; `LineSpec` sets color, line style, and marker |
| `figure` | `figure` or `f = figure` or `figure(n)` | Create a new figure window, or bring figure `n` to focus |
| `subplot` | `subplot(m,n,p)` or `ax = subplot(m,n,p)` | Divide the figure into an m-by-n grid and activate the p-th subplot panel |
| `hold` | `hold on` or `hold off` | `hold on` retains current plot when adding new graphics; `hold off` replaces it |
| `title` | `title(txt)` or `title(txt,Name,Value)` | Add a title string to the current axes |
| `xlabel` | `xlabel(txt)` | Label the x-axis of the current axes |
| `ylabel` | `ylabel(txt)` | Label the y-axis of the current axes |
| `legend` | `legend(label1,label2,...)` or `legend(Name,Value)` | Add a legend to the current axes using the specified labels |
| `axis` | `axis([xmin xmax ymin ymax])` or `axis style` | Set axis limits or apply a named style such as `equal`, `tight`, or `off` |
| `xlim` | `xlim([xmin xmax])` or `xl = xlim` | Set or get the x-axis limits of the current axes |
| `ylim` | `ylim([ymin ymax])` or `yl = ylim` | Set or get the y-axis limits of the current axes |
| `grid` | `grid on` or `grid off` | Toggle major grid lines on the current axes |
| `bar` | `bar(x,y)` or `bar(y)` | Create a vertical bar chart |
| `histogram` | `histogram(X)` or `histogram(X,nbins)` | Plot a frequency histogram; auto-bins data or uses specified number of bins |
| `scatter` | `scatter(x,y)` or `scatter(x,y,sz,c)` | Create a 2-D scatter plot with optional marker size and color data |
| `imagesc` | `imagesc(C)` or `imagesc(x,y,C)` | Display matrix data as an image with scaled colors mapping to the colormap |
| `colorbar` | `colorbar` or `colorbar(location)` | Display a colorbar showing the color scale for the current axes |
| `saveas` | `saveas(fig,filename)` or `saveas(fig,filename,format)` | Save a figure to a file; format inferred from extension or specified explicitly |

### File I/O Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `load` | `load(filename)` or `S = load(filename)` or `load(filename,vars)` | Load variables from a `.mat` file or columnar ASCII data file into the workspace |
| `save` | `save(filename)` or `save(filename,vars)` or `save(filename,vars,'-v7.3')` | Save workspace variables to a `.mat` file; version flag selects MAT-file format |
| `fopen` | `fileID = fopen(filename)` or `fileID = fopen(filename,permission)` | Open a file for reading or writing; returns an integer file identifier |
| `fclose` | `fclose(fileID)` or `fclose('all')` | Close an open file or all open files |
| `fread` | `A = fread(fileID)` or `A = fread(fileID,count,precision)` | Read binary data from a file into an array |
| `fwrite` | `count = fwrite(fileID,A)` or `count = fwrite(fileID,A,precision)` | Write binary data from an array to a file |
| `fscanf` | `A = fscanf(fileID,format)` or `[A,count] = fscanf(fileID,format,size)` | Read formatted text data from a file according to a C-style format string |
| `fprintf` | `fprintf(fileID,format,A,...)` | Write formatted text to a file (same function as the string-output `fprintf`) |
| `textscan` | `C = textscan(fileID,format)` or `C = textscan(str,format)` | Read formatted data from a text file or string into a cell array |
| `readtable` | `T = readtable(filename)` or `T = readtable(filename,Name,Value)` | Read a delimited text or spreadsheet file into a `table` |
| `writetable` | `writetable(T,filename)` or `writetable(T,filename,Name,Value)` | Write a `table` to a delimited text or spreadsheet file |
| `csvread` | `M = csvread(filename)` or `M = csvread(filename,R1,C1)` | Read a CSV file into a numeric matrix (legacy; prefer `readmatrix`) |
| `csvwrite` | `csvwrite(filename,M)` | Write a numeric matrix to a CSV file (legacy; prefer `writematrix`) |
| `xlsread` | `num = xlsread(filename)` or `[num,txt,raw] = xlsread(filename,sheet,range)` | Read an Excel spreadsheet; returns numeric, text, and raw cell data (legacy; prefer `readtable` or `readmatrix`) |

### Type Checking & Control Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `error` | `error(msg)` or `error(id,msg,A,...)` | Throw an error and display a message; halts execution and unwinds the call stack |
| `warning` | `warning(msg)` or `warning(id,msg,A,...)` | Issue a warning message without halting execution |
| `assert` | `assert(cond)` or `assert(cond,msg)` or `assert(A,B,tol)` | Throw an error if condition is false; optionally checks numeric equality within tolerance |
| `return` | `return` | Exit the current function immediately and return to the calling context |
| `input` | `x = input(prompt)` or `str = input(prompt,'s')` | Display a prompt and wait for user input; `'s'` returns input as a string |
| `disp` | `disp(X)` | Display the value of `X` without printing the variable name |
| `display` | `display(X)` | Display `X` with its variable name (called automatically when a statement produces output) |
| `class` | `c = class(X)` | Return the data type (class) of `X` as a character vector, e.g., `'double'`, `'char'` |
| `isa` | `tf = isa(X,classname)` | Return true if `X` belongs to the specified class or one of its subclasses |
| `isnumeric` | `tf = isnumeric(X)` | Return true if `X` is a numeric array |
| `ischar` | `tf = ischar(X)` | Return true if `X` is a character array (char type) |
| `isempty` | `tf = isempty(X)` | Return true if `X` is an empty array (any dimension is zero) |
| `isnan` | `tf = isnan(X)` | Return a logical array that is true where elements of `X` are `NaN` |
| `isinf` | `tf = isinf(X)` | Return a logical array that is true where elements of `X` are `+Inf` or `-Inf` |
| `exist` | `n = exist(name)` or `n = exist(name,type)` | Check whether a variable, file, folder, or class exists; returns a numeric code indicating type |

---

## Common Error Messages

A reference of frequently encountered MATLAB errors and warnings, organized by category. Each entry lists the exact message text MATLAB produces, what it means in plain English, what typically causes it, and how to fix it.

### Dimension Mismatch Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Inner matrix dimensions must agree.` | The number of columns in the left matrix does not equal the number of rows in the right matrix for `*` multiplication. | Using `*` instead of `.*`, or multiplying matrices/vectors whose sizes are incompatible (e.g., a 3x2 times a 3x1). | Check `size()` of both operands. Use `.*` for element-wise multiplication, or transpose one operand so inner dimensions match. |
| `Matrix dimensions must agree.` | Two arrays in an element-wise operation (`+`, `-`, `.*`, `./`, etc.) do not have the same size. | Adding or subtracting vectors/matrices of different lengths or shapes (e.g., a 1x3 plus a 1x4). | Verify both arrays have identical dimensions with `size()`. Reshape or transpose one operand as needed. |
| `Dimensions of arrays being concatenated are not consistent.` | Arrays being joined with `[ ]`, `horzcat`, or `vertcat` have mismatched sizes along the concatenation dimension. | `[A; B]` where `A` has 3 columns and `B` has 4 columns, or `[A, B]` where row counts differ. | Ensure arrays share the same size along the non-concatenation dimension before combining them. |
| `Arrays have incompatible sizes for this operation.` | An element-wise operation was attempted on arrays whose sizes are not compatible even under implicit expansion (broadcasting). | Operating on a 3x1 vector and a 1x4 vector is fine (broadcasts to 3x4), but a 3x1 and a 2x1 is not. | Check `size()` of both arrays. For implicit expansion, non-singleton dimensions must match. |

### Undefined Variable / Function Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Undefined function or variable 'X'.` | MATLAB cannot find anything named `X` in the current scope or on the path. | Misspelled variable or function name; variable not yet assigned; function file not on the MATLAB path; forgot to run an earlier section of a script. | Check spelling and case. Make sure the variable is assigned before use. Use `addpath()` or `cd` if the function file is in another folder. |
| `Undefined function 'X' for input arguments of type 'Y'.` | A function named `X` exists but has no overload that accepts the given input type `Y`. | Passing a string to a function that expects a numeric input, or calling a toolbox function that is not installed. | Verify the input types with `class()`. Check the function's documentation for accepted input types. Confirm the required toolbox is installed with `ver`. |
| `Unrecognized function or variable 'X'.` | Same as "Undefined function or variable" but appears in some contexts (e.g., Simulink or live scripts). | Identical causes: typo, variable not in scope, function not on path. | Same fixes: check spelling, ensure assignment, verify path. |

### Index Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Index exceeds the number of array elements. Index must not exceed N.` | You tried to access element at a position beyond the array's total element count. | `A(10)` when `A` has only 5 elements; loop counter goes one step too far; off-by-one error. | Check `numel(A)` or `length(A)`. Fix loop bounds (e.g., use `1:length(A)` instead of a hardcoded limit). |
| `Index in position 1 exceeds array bounds. Index must not exceed N.` | Row index is larger than the number of rows in the matrix. | `A(5,1)` when `A` is 4x3; loop variable exceeds row count. | Check `size(A,1)` for the row dimension and ensure your index stays within bounds. |
| `Index in position 2 exceeds array bounds. Index must not exceed N.` | Column index is larger than the number of columns in the matrix. | `A(1,5)` when `A` is 4x3. | Check `size(A,2)` for the column dimension. |
| `Array indices must be positive integers or logical values.` | An index is zero, negative, fractional, or of a non-integer/non-logical type. | Using `A(0)` (MATLAB is 1-based); using a fractional result as an index; using a string as an index. | Ensure indices are positive whole numbers. Use `round()`, `floor()`, or `ceil()` if computing indices from arithmetic. Remember MATLAB indexing starts at 1. |
| `Index exceeds matrix dimensions.` | (Legacy, pre-R2018a form) An index is out of range for the matrix. | Same as "Index exceeds the number of array elements" above. | Same fixes: verify array size, check loop bounds. |

### Type Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Conversion to double from cell is not possible.` | You tried to store a cell array into a numeric array, or use a cell where a number is expected. | Using `()` indexing on a cell array (returns a cell) where `{}` indexing (returns contents) was needed; assigning cell data into a pre-allocated numeric array. | Use `C{k}` instead of `C(k)` to extract cell contents. Use `cell2mat()` to convert a cell array of numbers to a numeric array. |
| `Conversion to cell from double is not possible.` | You tried to store a number into a cell array using `{}` assignment incorrectly, or mix types in concatenation. | Assigning into a cell array with wrong syntax, or concatenating `[ ]` instead of `{ }`. | Use curly braces `{ }` for cell array construction and indexing. Use `num2cell()` to convert numeric arrays to cell arrays. |
| `Undefined operator '*' for input arguments of type 'cell'.` | An arithmetic operator was applied to a cell array instead of its numeric contents. | Forgetting to extract the numeric data from a cell with `{}` before doing math. | Extract contents with `{}` indexing or convert with `cell2mat()` before performing arithmetic. |
| `Operands to the logical and (&&) and logical or (\|\|) operators must be convertible to logical scalar values.` | The short-circuit operators `&&` or `\|\|` received a non-scalar or non-logical operand. | Using `&&` or `\|\|` with arrays instead of scalars; comparing vectors in an `if` condition. | Use element-wise `&` or `\|` for arrays, or reduce to scalar with `all()` or `any()` first. Use `&&`/`\|\|` only for scalar conditions. |

### Syntax Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Expression or statement is incorrect--possibly unbalanced (, {, or [.` | MATLAB's parser found an incomplete or malformed expression. | Missing a closing `)`, `]`, or `}`; forgetting an operator between terms; pasting code with hidden characters. | Count opening and closing brackets. Use the Editor's bracket matching (click a bracket to highlight its pair). |
| `Unbalanced or unexpected parenthesis or bracket.` | There is an extra or misplaced closing bracket/parenthesis without a matching opener. | Extra `)` or `]`; accidentally deleted an opening bracket; mismatched bracket types (e.g., opened with `(` but closed with `]`). | Count and match all bracket pairs. Use the Editor's matching highlight to find the mismatch. |
| `Invalid expression. Check for missing multiplication operator, missing or extra left parenthesis, or unbalanced delimiters.` | The parser cannot make sense of the expression as written. | Writing `2x` instead of `2*x`; implicit multiplication (not supported in MATLAB); missing operator. | Add explicit operators: `2*x`, not `2x`. Check for missing `*`, `+`, or other operators between terms. |
| `Parse error at 'X': usage might be invalid MATLAB syntax.` | The parser encountered an unexpected token. | Using syntax from another language (e.g., `x++`, `{key: value}`); missing `end` keyword. | Review MATLAB syntax rules. Replace constructs from other languages with MATLAB equivalents. |
| `The expression to the left of the equals sign is not a valid target for an assignment.` | The left side of `=` is something that cannot be assigned to. | Writing `x + 1 = y` instead of `y = x + 1`; trying to assign to a function call result like `sin(x) = 5`. | Put the variable to be assigned on the left side. Ensure the left side is a valid variable name or indexing expression. |

### File Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `File 'X.m' not found.` | MATLAB cannot locate the specified file. | The file does not exist, is in a different folder, or has a different name. | Verify the filename and check `pwd`. Use `which('X')` to see if MATLAB can find it. Add the folder to the path with `addpath()`. |
| `Function name 'X' must match the filename 'Y.m'.` | The `function` declaration name does not match the `.m` filename. | Renaming the file without updating the function line, or vice versa. | Make the function name on the first line match the filename exactly (case-sensitive on some OS). |
| `Not enough input arguments.` | A function was called with fewer arguments than its signature requires. | Calling `myFun(x)` when `myFun` requires two inputs; running a function file as a script by clicking Run instead of calling it with arguments. | Provide all required arguments. If testing, call the function from the Command Window with test inputs rather than clicking Run. |
| `Too many input arguments.` | A function was called with more arguments than it accepts. | Passing extra arguments; calling a built-in with unsupported options; confusing a script (which takes no arguments) with a function. | Check the function's signature with `help('X')`. Remove extra arguments. |
| `Too many output arguments.` | More output variables were requested than the function returns. | `[a,b,c] = size(A,1)` when that form returns only one output. | Check how many outputs the function supports with `help('X')`. Reduce the number of output variables. |
| `Invalid file identifier. Use fopen to generate a valid file identifier.` | A file I/O function received `-1` or an invalid `fid`. | `fopen` failed (file not found, permission denied) and returned `-1`, which was then passed to `fread`, `fprintf`, etc. | Always check the return value of `fopen`: `if fid == -1, error('Cannot open file'); end`. Verify the file path and permissions. |

### Assignment Errors

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Unable to perform assignment because the size of the left side is M-by-N and the size of the right side is P-by-Q.` | The value being assigned does not fit into the specified location in the target array. | `A(1,:) = [1 2 3]` when `A` has 4 columns; replacing a row/column with a vector of the wrong length. | Ensure the right side has the same dimensions as the target slice. Check with `size()` on both sides. |
| `Subscripted assignment dimension mismatch.` | (Legacy, pre-R2018a form) Same as "Unable to perform assignment because the size..." above. | Same causes: assigning a value whose shape does not match the indexed region. | Same fix: match dimensions of the source value to the target location. |
| `In an assignment A(:) = B, the number of elements in A and B must be the same.` | `A(:) = B` requires that `numel(A)` equals `numel(B)`. | Trying to overwrite all elements of `A` with a `B` that has a different total element count. | Ensure `numel(A) == numel(B)`, or reshape `B` to match before assignment. |
| `Assignment has more non-singleton rhs dimensions than non-singleton subscripts.` | The right side of an indexed assignment has more dimensions than the left side can accommodate. | Assigning a 2-D matrix into a single-index location, e.g., `A(1) = [1 2; 3 4]`. | Reduce the right side to a scalar for single-element assignment, or expand the indexing to cover the full target region. |

### Singular Matrix Warnings

| Error Message | What It Means | Typical Cause | Fix |
|---------------|---------------|---------------|-----|
| `Warning: Matrix is singular to working precision.` | The matrix has no inverse (determinant is effectively zero). The result will contain `Inf` or `NaN` values. | Calling `inv(A)` or using `A\b` on a matrix with linearly dependent rows/columns; a system of equations has no unique solution. | Check `det(A)` or `cond(A)` first. Use `pinv(A)` for a pseudo-inverse, or `rank(A)` to confirm rank deficiency. Reformulate the problem if the matrix is truly singular. |
| `Warning: Matrix is close to singular or badly scaled. Results may be inaccurate. RCOND = X.` | The matrix is nearly singular; results exist but may have large numerical errors. | A matrix with very large and very small entries; columns that are nearly linearly dependent; poorly scaled physical units. | Check `cond(A)`. Rescale the problem (normalize columns). Use `pinv(A)` or increase precision if possible. Consider whether the model itself is ill-posed. |

---

## Beginner Patterns

### Vectorization Over Loops

MATLAB is optimized for operations on entire arrays at once. Vectorized code runs faster
than explicit loops because it delegates work to highly optimized internal libraries (LAPACK,
BLAS) and avoids per-iteration interpreter overhead.

**Loop version (slow):**

```matlab
x = 1:1000000;
y = zeros(size(x));
for k = 1:length(x)
    y(k) = x(k)^2 + 3*x(k) - 5;
end
```

**Vectorized version (fast):**

```matlab
x = 1:1000000;
y = x.^2 + 3*x - 5;
```

Both produce identical results, but the vectorized version is typically 10-50x faster. As a
rule of thumb: if you find yourself writing a `for` loop that processes one element at a
time, look for an array operator or built-in function that can do the same work in one
statement.

### 1-Based Indexing

MATLAB arrays are indexed starting at 1, not 0. The first element of a vector `v` is
`v(1)`. The keyword `end` refers to the last index of a dimension.

```matlab
v = [10 20 30 40 50];

v(1)       % 10  — first element
v(end)     % 50  — last element
v(end-1)   % 40  — second-to-last element
v(2:4)     % [20 30 40] — elements 2 through 4
```

Attempting `v(0)` produces an error: "Array indices must be positive integers or logical
values."

### Matrix Construction

Semicolons separate rows. The colon operator creates evenly spaced sequences. `linspace`
creates a vector with a specified number of points.

```matlab
% Row vector — spaces or commas separate elements
row = [1 2 3 4 5];

% Column vector — semicolons separate elements
col = [1; 2; 3; 4; 5];

% 2x3 matrix — semicolons separate rows
A = [1 2 3; 4 5 6];

% Colon operator — start:step:stop
t = 0:0.5:2;          % [0 0.5 1.0 1.5 2.0]

% linspace — start, stop, number of points
x = linspace(0, 2*pi, 100);   % 100 evenly spaced points from 0 to 2*pi

% Special constructors
Z = zeros(3, 4);       % 3x4 matrix of zeros
O = ones(2, 2);        % 2x2 matrix of ones
I = eye(3);            % 3x3 identity matrix
```

### Basic Plotting Workflow

A complete example that generates a sine wave plot with labeled axes and a grid.

```matlab
x = linspace(0, 2*pi, 200);   % 200 points from 0 to 2*pi
y = sin(x);

figure;                         % open a new figure window
plot(x, y, 'b-', 'LineWidth', 1.5);  % blue solid line, 1.5 pt width
title('Sine Wave');
xlabel('x (radians)');
ylabel('sin(x)');
grid on;                        % overlay a grid
```

To add a second curve, use `hold on` before the next `plot` call, and add a `legend`:

```matlab
hold on;
plot(x, cos(x), 'r--', 'LineWidth', 1.5);  % red dashed line
legend('sin(x)', 'cos(x)');
hold off;
```

### Function File Structure

A function is saved in its own `.m` file whose name must match the function name. The first
line declares inputs and outputs.

```matlab
% File: computeArea.m
function area = computeArea(radius)
% COMPUTEAREA  Compute the area of a circle.
%   area = computeArea(radius) returns the area for the given radius.
%   radius can be a scalar or array.

    area = pi * radius.^2;
end
```

Key rules:
- The filename (`computeArea.m`) must match the function name (`computeArea`).
- The `%` comment block right after the function line becomes the help text shown by
  `help computeArea`.
- Use element-wise operators (`.^`) so the function works on arrays, not just scalars.

### Script vs Function

- **Script** (`.m` file with no `function` line)
  - Runs in the base workspace; all variables it creates persist in the caller's workspace.
  - Takes no input arguments and produces no output arguments.
  - Good for quick, one-off tasks, data-loading routines, and interactive exploration.
- **Function** (`.m` file beginning with `function`)
  - Has its own private workspace; variables inside are not visible outside.
  - Accepts input arguments and returns output arguments.
  - Good for reusable, testable code that should not interfere with other variables.

```matlab
% --- Script example (myScript.m) ---
% No function line; runs in the base workspace
x = linspace(0, 10, 50);
y = x.^2;
plot(x, y);

% --- Function example (square.m) ---
function y = square(x)
    y = x.^2;
end
```

---

## Gotchas

Common pitfalls that trip up MATLAB beginners. The third column shows the corrected approach.

| Gotcha | What Happens | What You Probably Wanted |
|--------|-------------|--------------------------|
| Missing semicolon at end of statement | Every result prints to the Command Window, flooding output and slowing execution. | Terminate assignments with `;` to suppress output: `x = 5;` |
| Using `=` instead of `==` in a condition | `if x = 5` is an assignment error, not a comparison. MATLAB throws "The expression to the left of the equals sign is not a valid target for an assignment." | Use the equality operator: `if x == 5` |
| `*` instead of `.*` | `A * B` performs matrix multiplication (inner dimensions must agree). Two 1x3 row vectors will error with "Incorrect dimensions." | Use `.*` for element-wise multiplication: `A .* B` |
| Row vs column vector confusion | `[1 2 3]` is 1x3 (row); `[1; 2; 3]` is 3x1 (column). Mixing them in operations causes dimension mismatch errors. | Be deliberate: use semicolons for column vectors, spaces/commas for row vectors. Transpose with `.'` when needed. |
| Using `i` or `j` as loop variables | Overwrites the built-in imaginary unit (`1i`, `1j`). Later complex arithmetic silently uses the loop variable's last value instead of sqrt(-1). | Use `1i` or `1j` for the imaginary unit (these cannot be overwritten), or choose other loop variable names like `k`, `m`, `n`. |
| Char array vs string confusion | `'hello'` creates a 1x5 `char` array; `"hello"` creates a 1x1 `string` scalar. Some functions treat them differently; concatenation rules differ. | Pick one type consistently. Use `"hello"` (double quotes) for `string` scalars in modern MATLAB (R2016b+). Convert with `string()` or `char()` when needed. |
| Expecting integer division | `7/2` returns `3.5`, not `3`. MATLAB defaults to `double` for all numeric literals. | Use `floor(7/2)`, `idivide(int32(7), int32(2))`, or `fix(7/2)` for truncated integer division. |
| Indexing into an empty array | `A = []; A(1)` errors with "Index exceeds the number of array elements (0)." Growing arrays by indexing past the end works, but reading past the end does not. | Check `isempty(A)` before indexing. Pre-allocate with `zeros` or `NaN` instead of starting from `[]`. |
| Functions cannot see base workspace variables | A function has its own workspace. Variables defined in the Command Window or a script are invisible inside a function body. | Pass values as input arguments. Avoid `global`; it creates hard-to-debug hidden dependencies. |
| `end` keyword overload | `end` both closes blocks (`if`/`for`/`function`) and means "last index" inside subscripts (`A(end)`). Misplacing `end` can close a block early or cause a cryptic parse error. | Match every block-opening keyword with exactly one `end`. Use the Editor's code folding and indentation to verify nesting. Inside indexing expressions, `end` always means last index. |

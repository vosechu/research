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

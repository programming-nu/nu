;; @file       help.nu
;; @discussion Help text for Nu.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Radtastical Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

(macro class-help (name text)
     `(progn
            (class ,name
                 (- (id) help is ,text))))

;; help text

(class-help Nu_car_operator <<-END
This operator gets the head of a list.END)

(class-help Nu_cdr_operator <<-END
This operator gets the rest of a list, excluding its head.END)

(class-help Nu_atom_operator <<-END
This operator tests whether an object is an atom.
In Nu, lists and nil are not atoms.
Everything else is an atom.END)

(class-help Nu_eq_operator <<-END
This operator tests a pair of objects for equality.END)

(class-help Nu_neq_operator <<-END
This operator tests that a pair of objects are not equal.END)

(class-help Nu_cons_operator <<-END
This operator constructs a list by joining a pair of elements.
The second element should be another list or nil.END)

(class-help Nu_append_operator <<-END
This operator appends two lists together.END)

(class-help Nu_cond_operator <<-END
This operator scans through a list of lists, evaluating the
first member of each list.  When one evaluates true, the
remainder of that list is evaluated and the result of the
last evaluation is returned.  If none evaluate true, the
last list in the list of lists is evaluated.END)

(class-help Nu_case_operator <<-END
This operator tests an expression against a sequence of values,
each at the head of a list.  When the expression matches a value,
the rest of that value's list is evaluated and the result of
the last evaluation is returned.  If none of the values match,
the last list in the list of lists is evaluated.END)

(class-help Nu_if_operator <<-END
This operator tests an expression.  If it evaluates true,
the rest of the expressions that follow are evaluated,
except for any expressions in a list beginning with the
"else" symbol.  These expressions will be evaluated
if the expression evaluates false.END)

(class-help Nu_unless_operator <<-END
This operator tests an expression.  If it evaluates false,
the rest of the expressions that follow are evaluated,
except for any expressions in a list beginning with the
"else" symbol.  These expressions will be evaluated
if the expression evaluates true.END)

(class-help Nu_while_operator <<-END
This operator tests an expression.  If it evaluates true,
the rest of the expressions that follow are evaluated.
Then the expression is tested again and evaluations continue
until the expression evaluates to false.END)

(class-help Nu_until_operator <<-END
This operator tests an expression.  If it evaluates false,
the rest of the expressions that follow are evaluated.
Then the expression is tested again and evaluations continue
until the expression evaluates to true.END)

(class-help Nu_for_operator <<-END
This operator acts like the C for loop. Its first argument
should be a list of three expressions that will be evaluated
(1) to initialize the loop, (2) to test whether to evaluate
loop body, and (3) to modify a state variable after each
time the loop body is evaluated.  The rest of the expressions
are used as the loop body.
For example, the following for expression prints the numbers
from 1 to 10:
(for ((set i 1) (<= i 10) (set i (+ i 1)))
     (puts i))
END)

(class-help Nu_break_operator <<-END
This operator throws an exception that will be caught by
the innermost while, until, or for loop, which will immediately
terminate.END)

(class-help Nu_continue_operator <<-END
This operator throws an exception that will be caught by
the innermost while, until, or for loop, which will immediately
continue to the next loop iteration.END)

(class-help Nu_try_operator <<-END
This operator wraps a sequence of statement evaluations in
an exception handler.  Expressions that follow are evaluated
until a list beginning with "catch" is reached.  The
expressions in this list are not evaluated unless an exception
is thrown by the evaluated expressions, in which case,
execution jumps to the code in the catch section.END)

(class-help Nu_throw_operator <<-END
This operator throws an exception.END)

(class-help Nu_synchronized_operator <<-END
This operator evaluates a list of expressions after synchronizing
on an object.  The synchronization object is the first argument.
For example:
(synchronized object
	(task1)
	(task2)
	...)
END)

(class-help Nu_quote_operator <<-END
This operator prevents the evaluation of its arguments.END)

(class-help Nu_eval_operator <<-END
This operator forces the evaluation of its arguments.END)

(class-help Nu_context_operator <<-END
This operator returns the current evaluation context.END)

(class-help Nu_set_operator <<-END
This operator sets the value of a symbol to the result of an
expression evaluation.END)

(class-help Nu_global_operator <<-END
This operator sets the global value of a symbol to the result
of an expression evaluation.END)

(class-help Nu_function_operator <<-END
This operator creates a named function in the current evaluation
context. It expects three arguments: the function name,
a list of function parameters, and the body of the function.END)

(class-help Nu_macro_1_operator <<-END
This operator creates a named macro in the current evaluation
context. It expects two arguments: the macro name, followed by
the body of the macro.END)

(class-help Nu_progn_operator <<-END
This operator evaluates a sequence of expression and returns
the result of the last evaluation.  Many Nu operators contain
implicit progn operators.END)

(class-help Nu_list_operator <<-END
This operator constructs a list from its arguments.END)

(class-help Nu_do_operator <<-END
This operator is used to create blocks.
For example, the following expression creates a
block that returns the sum of its two arguments:
(do (x y)
	(+ x y))
END)

(class-help Nu_puts_operator <<-END
This operator writes a string to the console.
The string is followed by a carriage return.END)

(class-help Nu_print_operator <<-END
This operator writes a string to the console.
The string is not followed by a carriage return.END)

(class-help Nu_load_operator <<-END
This operator loads a file or bundle.END)

(class-help Nu_class_operator <<-END
This operator defines or extends a class.
If a subclass is specified, presumably a new
class is to be created.  Subsequent lists
within the operator may be used to add
instance methods, class methods, and instance
variables to the class.END)

(class-help Nu_imethod_operator <<-END
This operator adds an instance method to a class.
It should only be used within a class operator.END)

(class-help Nu_cmethod_operator <<-END
This operator adds a class method to a class.
It should only be used within a class operator.END)

(class-help Nu_ivar_operator <<-END
This operator adds typed instance variables to a class.
It should only be used before any instances of the
associated class have been created.END)

(class-help Nu_ivars_operator <<-END
This operator adds dynamic instance variables to a class.
These variables are stored in a dictionary and may be
added at any time, but this operator should only be used
before any instances of the associated class have been
created.END)

(class-help Nu_send_operator <<-END
This operator sends a message to an object.  Normally
it is not needed, but for a few kinds of objects,
such as blocks, functions, and macros, the normal
list syntax for message sending is treated as a
call.  This operator was added to allow messages
to be sent to these objects.END)

(class-help Nu_let_operator <<-END
This operator performs bindings specified in a list
of name-value pairs, then evaluates a sequence of
expressions in the specified binding.END)

(class-help Nu_help_operator <<-END
This operator gets the help text for an object.END)

(class-help Nu_add_operator <<-END
Arithmetic operator.END)

(class-help Nu_subtract_operator <<-END
Arithmetic operator.END)

(class-help Nu_multiply_operator <<-END
Arithmetic operator.END)

(class-help Nu_divide_operator <<-END
Arithmetic operator.END)

(class-help Nu_bitwiseand_operator <<-END
Bitwise logical operator.END)

(class-help Nu_bitwiseor_operator <<-END
Bitwise logical operator.END)

(class-help Nu_greaterthan_operator <<-END
Comparison operator.END)

(class-help Nu_lessthan_operator <<-END
Comparison operator.END)

(class-help Nu_gte_operator <<-END
Comparison operator.END)

(class-help Nu_lte_operator <<-END
Comparison operator.END)

(class-help Nu_leftshift_operator <<-END
Shift operator.END)

(class-help Nu_rightshift_operator <<-END
Shift operator.END)

(class-help Nu_and_operator <<-END
Logical operator.END)

(class-help Nu_or_operator <<-END
Logical operator.END)

(class-help Nu_not_operator <<-END
Logical operator.END)

(class-help Nu_version_operator <<-END
This operator returns a string describing the current version.END)

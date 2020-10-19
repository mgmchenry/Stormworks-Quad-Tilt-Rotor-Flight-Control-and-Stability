
--[[
PID notes -

https://www.reddit.com/r/Stormworks/comments/dk6kah/how_to_set_up_pid_ziglernicolson_method/
How to set up PiD (Zigler-Nicolson Method)
Como Volto V2 RIP since 0.9.6
https://steamcommunity.com/sharedfiles/filedetails/?id=1895231045

--]]

--[[

The string.char and string.byte functions convert between characters and their internal numeric representations. The function string.char gets zero or more integers, converts each one to a character, and returns a string concatenating all those characters. The function string.byte(s, i) returns the internal numeric representation of the i-th character of the string s; the second argument is optional, so that a call string.byte(s) returns the internal numeric representation of the first (or single) character of s. In the following examples, we assume that characters are represented in ASCII:

    print(string.char(97))                    -->  a
    i = 99; print(string.char(i, i+1, i+2))   -->  cde
    print(string.byte("abc"))                 -->  97
    print(string.byte("abc", 2))              -->  98
    print(string.byte("abc", -1))             -->  99
In the last line, we used a negative index to access the last character of the string.
The function string.format is a powerful tool when formatting strings, typically for output. It returns a formatted version of its variable number of arguments following the description given by its first argument, the so-called format string. The format string has rules similar to those of the printf function of standard C: It is composed of regular text and directives, which control where and how each argument must be placed in the formatted string. A simple directive is the character `%´ plus a letter that tells how to format the argument: `d´ for a decimal number, `x´ for hexadecimal, `o´ for octal, `f´ for a floating-point number, `s´ for strings, plus other variants. Between the `%´ and the letter, a directive can include other options, which control the details of the format, such as the number of decimal digits of a floating-point number:

    print(string.format("pi = %.4f", PI))     --> pi = 3.1416
    d = 5; m = 11; y = 1990
    print(string.format("%02d/%02d/%04d", d, m, y))
      --> 05/11/1990
    tag, title = "h1", "a title"
    print(string.format("<%s>%s</%s>", tag, title, tag))
      --> <h1>a title</h1>
In the first example, the %.4f means a floating-point number with four digits after the decimal point. In the second example, the %02d means a decimal number (`d´), with at least two digits and zero padding; the directive %2d, without the zero, would use blanks for padding. For a complete description of those directives, see the Lua reference manual. Or, better yet, see a C manual, as Lua calls the standard C libraries to do the hard work here.

--]]
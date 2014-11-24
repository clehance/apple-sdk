#pragma once

#pragma mark - Memory related macros

/*!
 * @abstract It defines the NULL macro if the current platform doesn't define it.
 */
#ifndef NULL
    #define NULL    ((void*) 0)
#endif

#undef malloc_sizeof
/*!
 * @abstract Convenience macro to not have to write all the time malloc( sizeof(TYPE) )
 */
#define malloc_sizeof(VAR)  malloc( sizeof(VAR) )




#pragma mark - Likely/unlike optimizations

#undef likely
/*!
 * @abstract The CPU prefecthes the instructions of the if statement.
 * @details Meant to be use with booleans in the following form: if (likely(a > 14)) {...}
 *          To enable to likely/unlikely optimizations, you must set the -freorder-blocks flag when compiling the code (that flag is enable in -O2, but disable on -OS).
 */
#define likely(x)	__builtin_expect(!!(x),1)

#undef unlikely
/*!
 * @abstract The CPU prefetches the instructions outside the if statement (it tries to skip the if block).
 * @details Meant to be use with booleans in the following form: if (unlikely(a<13)) {...}
 *          To enable to likely/unlikely optimizations, you must set the -freorder-blocks flag when compiling the code (that flag is enable in -O2, but disable on -OS).
 */
#define unlikely(x)	__builtin_expect(!!(x),0)




#pragma mark - Verification macros

// This command won't do anything if the condition is true (which is what it is expected). If the condition is false, then "errno" is set to zero and the code will jump to the label error: (be sure to implement it).

#undef verifymem
/*!
 * @abstract It verifies that the ptr to memory is different than NULL.
 * @details If the pointer is NULL, a goto statement is fired with the name of the label passed as argument.
 *
 * @param ptr Pointer to memory.
 * @param goto_label Label indicating the branching path that will be executed if the assertion is not true.
 */
#define verifymem(ptr, goto_label)              if (ptr == NULL) { goto goto_label; }

#undef verify1
/*!
 * @abstract It verifies that the assertion passed as the first argument is true. If it is not, it jumps to the goto_label.
 *
 * @param assertion Expression/Value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertion is not true.
 */
#define verify1(assertion, goto_label)          if ( !(assertion) ) { goto goto_label; }

#undef verify2
/*!
 * @abstract It verifies that both of the assertions passed are true. If any of them (or both) are false, the program jumps to the goto_label.
 *
 * @param assertA Expression/value that must be evaluated to true.
 * @param assertB Expression/value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertions are not true.
 */
#define verify2(assertA, assertB, goto_label)   if ( !(assertA)) || !(assertB) ) { goto goto_label; }

#undef verify3
/*!
 * @abstract It verifies that all assertions are true. If any of them (or all) are false, the program jumps to the goto_label.
 *
 * @param assertA Expression/value that must be evaluated to true.
 * @param assertB Expression/value that must be evaluated to true.
 * @param assertC Expression/value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertions are not true.
 */
#define verify3(assertA, assertB, assertC, goto_label)              if ( unlikely(unlikely(unlikely(!(assertA)) || unlikely(!(assertB))) || unlikely(!(assertC))) ) { goto goto_label; }

#undef verify4
/*!
 * @abstract It verifies that all assertions are true. If any of them (or all) are false, the program jumps to the goto_label.
 *
 * @param assertA Expression/value that must be evaluated to true.
 * @param assertB Expression/value that must be evaluated to true.
 * @param assertC Expression/value that must be evaluated to true.
 * @param assertD Expression/value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertions are not true.
 */
#define verify4(assertA, assertB, assertC, assertD, goto_label)     if ( !(assertA) || !(assertB) || !(assertC) || !(assertD) ) { goto goto_label; }

#undef verifymem_opt
/*!
 * @abstract It verifies that the ptr to memory is different than NULL. It also expected to be not NULL, thus a "unlikely" macro is inserted.
 * @details If the pointer is NULL, a goto statement is fired with the name of the label passed as argument.
 *
 * @param ptr Pointer to memory.
 * @param goto_label Label indicating the branching path that will be executed if the assertion is not true.
 */
#define verifymem_opt(ptr, goto_label)          if ( unlikely(ptr == NULL) ) { goto goto_label; }

#undef verify1_opt
/*!
 * @abstract It verifies that the assertion passed as the first argument is true. If it is not, it jumps to the goto_label.
 * @details The "verify_opt" macro family expect that all the assertion given are always true; thus "unlikely" macros are used. Only use the "verify" macros when you are certain that the assertions are true (like memory checking). In other case you will suffer performance penalties.
 *
 * @param assertion Expression/Value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertion is not true.
 */
#define verify1_opt(assertion, goto_label)      if ( unlikely(!(assertion)) ) { goto goto_label; }

#undef verify2_opt
/*!
 * @abstract It verifies that both of the assertions passed are true. If any of them (or both) are false, the program jumps to the goto_label.
 * @details The "verify_opt" macro family expect that all the assertion given are always true; thus "unlikely" macros are used. Only use the "verify" macros when you are certain that the assertions are true (like memory checking). In other case you will suffer performance penalties.
 *
 * @param assertA Expression/value that must be evaluated to true.
 * @param assertB Expression/value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertions are not true.
 */
#define verify2_opt(assertA, assertB, goto_label)   if ( unlikely(unlikely(!(assertA)) || unlikely(!(assertB))) ) { goto goto_label; }

#undef verify3_opt
/*!
 * @abstract It verifies that all assertions are true. If any of them (or all) are false, the program jumps to the goto_label.
 * @details The "verify_opt" macro family expect that all the assertion given are always true; thus "unlikely" macros are used. Only use the "verify" macros when you are certain that the assertions are true (like memory checking). In other case you will suffer performance penalties.
 *
 * @param assertA Expression/value that must be evaluated to true.
 * @param assertB Expression/value that must be evaluated to true.
 * @param assertC Expression/value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertions are not true.
 */
#define verify3_opt(assertA, assertB, assertC, goto_label)  if ( unlikely(unlikely(unlikely(!(assertA)) || unlikely(!(assertB))) || unlikely(!(assertC))) ) { goto goto_label; }

#undef verify4
/*!
 * @abstract It verifies that all assertions are true. If any of them (or all) are false, the program jumps to the goto_label.
 * @details The "verify_opt" macro family expect that all the assertion given are always true; thus "unlikely" macros are used. Only use the "verify" macros when you are certain that the assertions are true (like memory checking). In other case you will suffer performance penalties.
 *
 * @param assertA Expression/value that must be evaluated to true.
 * @param assertB Expression/value that must be evaluated to true.
 * @param assertC Expression/value that must be evaluated to true.
 * @param assertD Expression/value that must be evaluated to true.
 * @param goto_label Label indicating the branching path that will be executed if the assertions are not true.
 */
#define verify4_opt(assertA, assertB, assertC, assertD, goto_label) if ( unlikely(unlikely(unlikely(unlikely(!(assertA)) || unlikely(!(assertB))) || unlikely(!(assertC))) || unlikely((!assertD))) ) { goto goto_label; }




#pragma mark - Stringify and token concatenation

#undef stringify_macro_arg_name
/*!
 * @abstract It makes the text passed in the argument a valid C string.
 * @details This works with the preprocesing operator "#". Remember that unlike normal parameter replacement, the argument of the # preprocesing operator is not macro-expanded first.
 */
#define stringify_macro_arg_name(arg)     #arg

#undef stringify_macro_arg_value
/*!
 * @abstract It will expand the argument, and then convert that into a valid C string.
 */
#define stringify_macro_arg_value(arg) stringify_macro_arg_name(arg)

#undef concatenate_tokens
/*!
 * @abstract It will concatenate two tokens into a single one.
 */
#define concatenate_tokens(token_a, token_b)    token_a ## token_b

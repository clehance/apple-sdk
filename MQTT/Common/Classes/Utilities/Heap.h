#pragma once

#if defined(HIGH_PERFORMANCE)
#define NO_HEAP_TRACKING 1
#endif

#include <stdio.h>
#include <memory.h>
#include <stdlib.h>

#if !defined(NO_HEAP_TRACKING)
/**
 * redefines malloc to use "mymalloc" so that heap allocation can be tracked
 * @param x the size of the item to be allocated
 * @return the pointer to the item allocated, or NULL
 */
#define malloc(x) mymalloc(__FILE__, __LINE__, x)

/**
 * redefines realloc to use "myrealloc" so that heap allocation can be tracked
 * @param a the heap item to be reallocated
 * @param b the new size of the item
 * @return the new pointer to the heap item
 */
#define realloc(a, b) myrealloc(__FILE__, __LINE__, a, b)

/**
 * redefines free to use "myfree" so that heap allocation can be tracked
 * @param x the size of the item to be freed
 */
#define free(x) myfree(__FILE__, __LINE__, x)

#endif

/**
 * Information about the state of the heap.
 */
typedef struct
{
	int current_size;	/**< current size of the heap in bytes */
	int max_size;		/**< max size the heap has reached in bytes */
} heap_info;


void* mymalloc(char*, int, size_t size);
void* myrealloc(char*, int, void* p, size_t size);
void myfree(char*, int, void* p);

void Heap_scan(FILE* file);
int Heap_initialize(void);
void Heap_terminate(void);
heap_info* Heap_get_info(void);
int HeapDump(FILE* file);
int HeapDumpString(FILE* file, char* str);
void* Heap_findItem(void* p);
void Heap_unlink(char* file, int line, void* p);

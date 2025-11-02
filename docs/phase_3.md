# Phase 3

### Objective is to learn more about makefile

- We need to create a makefile that can auto generate dependencies for a C program

**a.c** :
```c
#include <stdio.h>
#include "a.h"
void functionA() { printf("This is functionA from a.c\n"); }
int main() {
    functionA();
    return 0; }
```

**a.h** :
```c
#ifndef A_H
#define A_H
void functionA();
#endif // A_H
```

**b.c** :
```c
#include <stdio.h>
#include "b.h"
void functionB() { printf("This is functionB from b.c\n"); }
int main() {
    functionB();
    return 0; }
```

**b.h** :
```c
#ifndef B_H
#define B_H
void functionB();
#endif // B_H
```

Makefile:
```make
CC = gcc
CFLAGS = -Wall -MMD -MP
SRC = a.c b.c
OBJ = $(SRC:.c=.o)
DEPS = $(SRC:.c=.d)
TARGETS = a b

all: $(TARGETS)

# Create executables from object files
%: %.o
	$(CC) $(CFLAGS) -o $@ $<

# Compiling .c to .o
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Include generated dependencies
-include $(DEPS)

run: $(TARGETS)
	@for target in $(TARGETS); do ./$$target; done

clean:
	rm -f $(TARGETS) $(OBJ) $(DEPS)
```

Some other things to keep in mind:
- `GCC` is compiler used
- `-Wall` enables all common warnings
- `-MMD` Generates a dependency file (`.d`) for each `.c` file
- `-MP` ensures missing headers don't break the build
- `SRC` is list of source files (`a.c`, `b.c`)
- `OBJ` converts `.c` filenames to `.o` (object files)
- `DEPS` converts `.c` filenames to `.d` (dependency files)

How it works:
1. `all` builds all executables listed in TARGETS (`a` and `b`)
2. `%: %.o` links a single object file (`%.o`) into an executable (`%`) (ex: `a.o` → `a`)
3. `%.o: %.c` compiles a `.c` file into an `.o` file
4. `-include $(DEPS)` includes the dependency files (`.d`), ensuring automatic tracking of header file dependencies
5. `run` runs all compiled executables (`a` and `b`)
6. `clean` deletes all compiled files (`.o`, `.d`, and executables)

To use we input commands:
```bash
~$ make run
~$ make clean
```

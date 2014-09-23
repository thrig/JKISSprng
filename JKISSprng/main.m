//
//  main.m
//  jkissprngstats - generates output from JKISSprng
//
//  Copyright (c) 2014 Jeremy Mates. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <err.h>
#import <sysexits.h>
#import "JKISSprng.h"

unsigned long long Flag_Count;                  // -c
unsigned long long Flag_Reseed;                 // -R
unsigned long long Flag_SeedX;                  // -X
unsigned long long Flag_SeedY;                  // -Y

const char *Program_Name;

void emit_help(void);
void (^methodcall)(void);

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        int ch;
        
        Program_Name = *argv;

        while ((ch = getopt(argc, (char * const *)argv, "c:h?R:X:Y:")) != -1) {
            switch (ch) {
                case 'c':
                    if (sscanf(optarg, "%llu", &Flag_Count) != 1)
                        errx(EX_DATAERR, "could not parse -c count option");
                    break;
                    
                case 'R':
                    if (sscanf(optarg, "%llu", &Flag_Reseed) != 1)
                        errx(EX_DATAERR, "could not parse -R reseed option");
                    break;
                    
                case 'X':
                    if (sscanf(optarg, "%llu", &Flag_SeedX) != 1)
                        errx(EX_DATAERR, "could not parse -X seed option");
                    break;
                    
                case 'Y':
                    if (sscanf(optarg, "%llu", &Flag_SeedY) != 1)
                        errx(EX_DATAERR, "could not parse -Y seed option");
                    break;
                    
                case 'h':
                case '?':
                default:
                    emit_help();
                    /* NOTREACHED */
            }
        }
        argc -= optind;
        argv += optind;
        
        if (argc == 0) {
            warnx("need method name to test");
            emit_help();
        }

        JKISSprng *fate = [JKISSprng new];
        if (Flag_SeedY != 0) {
            [fate setSeedX:Flag_SeedX SeedY:Flag_SeedY];
            Flag_Reseed = 0;
        } else {
            if ([fate twizzleSeeds:NULL] == NO)
                errx(EX_OSERR, "could not set seed from /dev/random ??");
        }

        if (Flag_Count == 0)
            Flag_Count = 1;
        if (Flag_Reseed >= Flag_Count)
            warnx("reseed option -R useless when >= count -c option");
        
        NSString *methodName = [[NSString alloc] initWithCString:*argv++
                                                        encoding:NSUTF8StringEncoding];
        char *linep = NULL;
        const char *fname;
        FILE *fh;
        size_t len = 0;
        
        NSMutableArray *theList = [[NSMutableArray alloc] init];
        NSMutableSet *theSet = [[NSMutableSet alloc] init];
        unsigned int precision = 4;
        long rollnum;
        
        if ([methodName isEqualToString:@"randomArrayMember"]) {
            if (!*argv || strncmp(*argv, "-", (size_t) 2) == 0) {
                fh = stdin;
                fname = "-";
            } else {
                if ((fh = fopen(*argv, "r")) == NULL)
                    err(EX_IOERR, "could not open '%s'", *argv);
                fname = *argv;
            }
            while (getline(&linep, &len, fh) > 0) {
                NSString *s = [[NSString alloc] initWithCString:linep
                                                       encoding:NSUTF8StringEncoding];
                [theList addObject:s];
            }
            if (ferror(fh))
                err(EX_IOERR, "error reading input file %s", fname);;
            if ([theList count] < 2)
                errx(EX_USAGE, "need at least two elements in array");
            
            methodcall = ^(void) {
                NSString *s = [fate randomArrayMember:theList];
                printf("%s", [s cStringUsingEncoding:NSUTF8StringEncoding]);
            };
            
        } else if ([methodName isEqualToString:@"randomFloat"]) {
            if (*argv && sscanf(*argv, "%u", &precision) != 1)
                errx(EX_DATAERR, "could not parse precision");
            if (precision < 1)
                precision = 1;
            else if (precision > 64)
                precision = 64;

            methodcall = ^(void) {
                printf("%.*f\n", precision, [fate randomFloat]);
            };
            
        } else if ([methodName isEqualToString:@"randomNumber"]) {
            methodcall = ^(void) {
                printf("%llu\n", [fate randomNumber]);
            };
            
        } else if ([methodName isEqualToString:@"randomSetMember"]) {
            if (!*argv || strncmp(*argv, "-", (size_t) 2) == 0) {
                fh = stdin;
                fname = "-";
            } else {
                if ((fh = fopen(*argv, "r")) == NULL)
                    err(EX_IOERR, "could not open '%s'", *argv);
                fname = *argv;
            }
            
            while (getline(&linep, &len, fh) > 0) {
                NSString *s = [[NSString alloc] initWithCString:linep
                                                       encoding:NSUTF8StringEncoding];
                [theSet addObject:s];
            }
            if (ferror(fh))
                err(EX_IOERR, "error reading input file %s", fname);
            if ([theSet count] < 2)
                errx(EX_USAGE, "need at least two elements in set");
            
            methodcall = ^(void) {
                NSString *s = [fate randomSetMember:theSet];
                printf("%s", [s cStringUsingEncoding:NSUTF8StringEncoding]);
            };
            
        } else if ([methodName isEqualToString:@"rollD"]) {
            if (!*argv) {
                warnx("rollD needs magnitude of roll where r > 1");
                emit_help();
            }
            if (sscanf(*argv, "%ld", &rollnum) != 1)
                errx(EX_DATAERR, "could not parse roll number");

            methodcall = ^(void) {
                printf("%lu\n", [fate rollD:rollnum]);
            };
        }
        
        for (unsigned long long i = 0; i < Flag_Count; i++) {
            methodcall();
            
            if (Flag_Reseed != 0 && i % Flag_Reseed == 0) {
                if ([fate twizzleSeeds:NULL] == NO)
                    errx(EX_OSERR, "could not set seed from /dev/random ??");
            }
        }
    }
    
    exit(EXIT_SUCCESS);
}

void emit_help(void)
{
    const char *shortname;
    if ((shortname = strrchr(Program_Name, '/')) != NULL)
        shortname++;
    else
        shortname = Program_Name;

    fprintf(stderr,
            "Usage: %s [-c count] [-R reseedcount] method [args]\n\n"
            "  Methods:\n"
            "    randomArrayMember [file|-]\n"
            "    randomFloat [precision]\n"
            "    randomNumber\n"
            "    randomSetMember [file|-]\n"
            "    rollD rollnum\n", shortname
            );
    
    exit(EX_USAGE);
}


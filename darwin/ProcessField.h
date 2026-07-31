#ifndef HEADER_DarwinProcessField
#define HEADER_DarwinProcessField
/*
htop - darwin/ProcessField.h
(C) 2020 htop dev team
Released under the GNU GPLv2+, see the COPYING file
in the source distribution for its full text.
*/


#define PLATFORM_PROCESS_FIELDS  \
   TRANSLATED = 100,             \
   RSS = 101,                    \
   IO_READ_RATE = 102,           \
   IO_WRITE_RATE = 103,          \
   IO_RATE = 104,                \
                                 \
   DUMMY_BUMP_FIELD = CWD,       \
   // End of list


#endif /* HEADER_DarwinProcessField */

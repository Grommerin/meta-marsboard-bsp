/* -*- linux-c -*- */

/*
 *  ussp.h
 *
 *  Copyright (C) 2000 R.E.Wolff@BitWizard.nl, patrick@BitWizard.nl
 *
 *  Version 1.0 July 2000 .
 *
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Street #330, Boston, MA 02111-1307, USA.
 */

#define USSP_WRITE       1
#define USSP_READ        2
#define USSP_SET_TERMIOS 3
#define USSP_MSC         4
#define USSP_OPEN        5
#define USSP_CLOSE       6
#define USSP_OPEN_RESULT 7
#define USSP_FORCE_CLOSE 8

/* Don't clash with normal openflags */
#define USSP_ISCALLOUT   0x10000000


#define USSP_MAX_PORTS 16


struct ussp_operation {
       int op;
       unsigned long len;	
       unsigned long arg;
       unsigned char data[0];
};


struct stats {
	int rxcount, txcount;
};


#define USSP_SET_PORT         _IOW('U', 1, int)
#define USSP_SET_PORT_WATCHER _IOW('U', 2, int)
#define TIOSTATGET            _IOW('U', 3, void *)

#define USSP_DEAMON_PRESENT  0x00000001

#ifdef __KERNEL__


struct ussp_port {
  int                     flags;
  int                     nusers;
  int			  line_status;
  wait_queue_head_t       daemon_wait;
  char                   *daemon_buffer;
  int                     daemon_head, daemon_tail;
  wait_queue_head_t       tty_wait;
  char                   *tty_buffer;
  int                     tty_head, tty_tail;
  struct stats            stats;
  int                     deamon_pid;

  struct termios          normal_termios;
  struct termios          callout_termios;
  struct tty_struct      *tty;
};
#endif

#define USSP_DCD TIOCM_CAR
#define USSP_RI  TIOCM_RNG
#define USSP_RTS TIOCM_RTS
#define USSP_CTS TIOCM_CTS
#define USSP_DTR TIOCM_DTR
#define USSP_DSR TIOCM_DSR


#ifndef USSPCTL_MISC_MINOR 
/* Allow others to gather this into "major.h" or something like that */
#define USSPCTL_MISC_MINOR    189
#endif

#ifndef USSP_NORMAL_MAJOR
/* This allows overriding on the compiler commandline, or in a "major.h" 
   include or something like that */
#define USSP_NORMAL_MAJOR  208
#define USSP_CALLOUT_MAJOR 209
#endif


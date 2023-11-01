
/*
    BH - writes header portion of BGI driver

    Copyright (c) 1988,89 Borland International

    and variously adapted by others
*/

#define UPDATE		"3.53"
#define AUTHOR		"edsa"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* BGI Driver Type information */
#define VERSION 	3		/* Version Number of header	*/
#define REVISION	0		/* Revision number of header	*/
#define MIN_VERSION	3		/* Minimum Version Number	*/
#define MIN_REVISION	0		/* Minimum Revision Number	*/
#define HEADER_SIZE	160		/* Size (in bytes) of header	*/

FILE	*Ifile, *Ofile = stdout, *Imapfile;

char mask[] = "FBGD\010\010\010\010BGI Device Driver (%s) " UPDATE " - " __DATE__ "\r\n"
	      "(c) 1991-95 Ullrich von Bassewitz. Update by " AUTHOR "\r\n";

char help[] = "BGI Type-3 Driver Builder\n\n"
	      "Usage is:  BH3 input[.BIN] output[.BGI] mapfile[.MAP] [drv_name]\n\n"
	      "    input.BIN is the DRIVER.BIN from EXE2BIN.\n"
	      "    output.BGI is the DRIVER.BGI file name.\n"
	      "    mapfile.MAP is the mapfile from linker containing segment info.\n"
	      "    drv_name is the device name in ASCII (i.e. EGA or CGA)\n";

int	drv_num = 0;
char	buf[80];
int	data, dlen;

/* convert hex string to an integer */
xtoi(char *hexstr, int *nbr)
{
  int d, t;
  char *cp;
  d = *nbr = 0; cp = hexstr;
  while ((*cp == ' ') | (*cp == '\n') | (*cp == '0')) cp++;
  while (1) {
    if ((*cp >= '0') & (*cp <= '9')) t = 48;
    else if ((*cp >= 'A') & (*cp <= 'F')) t = 55;
    else if ((*cp >= 'a') & (*cp <= 'f')) t = 87;
    else break;
    if ( d<4 ) ++d; else  return -1;
    *nbr = (*nbr << 4 ) + (*cp++ - t);
  }
  return d;
}

/* get data offset address from mapfile */
void readmap(void)
{
  int  len;
  while ( !feof(Imapfile) ) {
    fgets(buf, 80, Imapfile);
    if (strstr(buf,"DATA") && strstr(buf,"H")) {
      buf[strcspn(buf,"H")] = '\0';
      len = xtoi(buf,&data);
      if (len < 1) {
	fprintf( stderr,"ERROR: Invalid DATA offset value in .MAP file\n");
	exit( 5 );
      }
      goto done;
    }
  }
  fprintf( stderr,"ERROR: Could not find DATA offset in .MAP file\n");
  exit( 5 );
  done:;
}

void main( argc, argv )
int argc;
char *argv[];
{
  long int size, offset;
  int i, j;
  char name[80], *cptr;

  argv++;	argc--; 		/* Skip over program name	*/

  if( argc != 4 && argc != 5 ){ 	/* Must have input and output	*/
    fprintf( stderr, help );		/* Give user a help message	*/
    exit( 1 );				/* Leave the program		*/
    }

  strcpy( name, *argv++ );		/* Get input file name		*/
  cptr = strchr( name, '.' );           /* Is ther an extention?        */
  if( cptr ) *cptr = '\0';              /* Cut extent if give           */
  strcat( name, ".BIN" );               /* Add input file extention     */

  Ifile = fopen( name, "rb" );          /* Open input file              */
  if( NULL == Ifile ){			/* Did the open suceed? 	*/
    fprintf( stderr, "ERROR: Could not open input file %s.\n", *(argv-1) );
    exit( 2 );				/* Leave the program		*/
    }

  strcpy( name, *argv++ );		/* Get input file name		*/
  cptr = strchr( name, '.' );           /* Is ther an extention?        */
  if( cptr ) *cptr = '\0';              /* Cut extent if give           */
  strcat( name, ".BGI" );               /* Add input file extention     */

  Ofile = fopen( name, "wb" );          /* Open output file             */
  if( NULL == Ofile ){			/* Did the open suceed? 	*/
    fprintf( stderr, "ERROR: Could not open output file %s.\n", *(argv-1) );
    exit( 3 );				/* Leave the program		*/
    }

  strcpy( name, *argv++ );		/* Get input file name		*/
  cptr = strchr( name, '.' );           /* Is ther an extention?        */
  if( cptr ) *cptr = '\0';              /* Cut extent if give           */
  strcat( name, ".MAP" );               /* Add input file extention     */

  Imapfile = fopen( name, "rt" );	/* Open MAP file                */
  if( NULL == Imapfile ){		/* Did the open suceed? 	*/
    fprintf( stderr, "ERROR: Could not open .MAP file %s.\n", *(argv-1) );
    exit( 4 );				/* Leave the program		*/
  }
  readmap();

  strcpy( name, *argv++ );		/* Get driver name from line	*/
  strupr( name );			/* Convert name to uppercase	*/

/*	The driver number is not needed for version 2 drivers, but is	*/
/*	allowed for version 1 compatability.				*/

  if( argc == 5 )			/* Is driver number is present? */
    drv_num = atoi( *argv++ );		/* convert driver number to bin */

  fseek( Ifile, 0L, SEEK_END ); 	/* Goto the end of the file	*/
  size = ftell( Ifile );		/* Read the length of the file	*/

  dlen = ((int) size) - data;		/* Calc length of data segment	*/

  fseek( Ifile, 0L, SEEK_SET ); 	/* Goto the beginning of file	*/

  fprintf( Ofile, mask, name );
  putc( 0x00, Ofile );			/* Null terminate string in file*/
  putc( 0x1a, Ofile );			/* Control Z terminate file	*/

  putw( HEADER_SIZE, Ofile );		/* Write out the size of header */
  putw( drv_num, Ofile );		/* Write out the driver number	*/
  putw( data, Ofile );			/* Data offset (in bytes)	*/

  putc( VERSION, Ofile );		/* Write the version number	*/
  putc( REVISION, Ofile );		/* Write the revision number	*/

  putc( MIN_VERSION, Ofile );		/* Write the version number	*/
  putc( MIN_REVISION, Ofile );		/* Write the revision number	*/

  putw( data, Ofile );			/* Data offset (in bytes)	*/
  putw( dlen, Ofile );			/* Data size (in bytes)		*/

  offset = ftell( Ofile );		/* Find location in output file */
  for( i=(int)offset ; i<0x80 ; ++i ) putc( 0x00, Ofile );

  putw( HEADER_SIZE, Ofile );		/* Write out the size of header */
  putw( drv_num, Ofile );		/* Write out the driver number	*/
  putw( data, Ofile );			/* Data offset (in bytes)	*/

  putc( VERSION, Ofile );		/* Write the version number	*/
  putc( REVISION, Ofile );		/* Write the revision number	*/

  putc( MIN_VERSION, Ofile );		/* Write the version number	*/
  putc( MIN_REVISION, Ofile );		/* Write the revision number	*/

  putw( data, Ofile );			/* Data offset (in bytes)	*/
  putw( dlen, Ofile );			/* Data size (in bytes)		*/

  name[8] = '\0';                       /* Cut name to 8 characters     */
  j = strlen( name );			/* Get device driver int name	*/
  putc( j, Ofile );			/* Make string pascal format	*/
  for( i=0 ; i<j ; ++i ) putc( name[i], Ofile );

  size = ftell( Ofile );		/* How big is header so far	*/
  i = HEADER_SIZE - (int) size; 	/* Determine # of pad bytes	*/

  for( j=0 ; j<i ; ++j )		/* Pad header with zeros	*/
		putc( 0, Ofile );

  i = getc( Ifile );			/* Read source byte		*/
  while( !feof(Ifile) ){		/* Copy the input to output	*/
    putc( i, Ofile );			/* Write destination byte	*/
    i = getc( Ifile );			/* Read source byte		*/
    }

  fclose( Ifile );			/* Close file streams		*/
  fclose( Ofile );
  fclose( Imapfile );

}

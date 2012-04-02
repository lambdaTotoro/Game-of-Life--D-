/*	
	##################################################
	##                                              ##
	##      Conway's Game of Life                   ##
	##      (written in the D programming language) ##
	##                                              ##
	##      by Jonas Betzendahl, 2012               ##
	##      (jbetzend[at]techfak.uni-bielefeld.de)  ##
	##                                              ##
	##      Licence:                                ##
	##      Creative Commons Zero (Public Domain)   ##
	##                                              ##
	##################################################
*/

/* 	TODO: Change 2D-Array in 1D-Array. (x*width)+y and stuff. */
/*	TODO: Find terminal size and enlarge appropiately */
/*	TODO: Implement command line arguments. */

import std.stdio;			/* The usual standard In/Out-Stuff */
import std.conv;			/* Converting things into different things */
import std.random;			/* For (quasi-)random numbers */

import core.thread;
import core.time;


int		global_rows;
int		global_columns;
int 		global_generations;
int		global_history_size;
int		global_interval_length;

int[][] 	global_field;

int[][][] 	global_history;

bool		generations_freeze;
bool		loop;

string		CSI = "\33[";		/* arcane string for ANSI-Magic */
string		info;

void
pushGeneration(int[][] field, int size)
{
	/* Move all old generations "one to the back" */

	for (int a=1; a<size; a++)
	{
		for (int b=0; b<global_rows; b++)
		{
			for (int c=0; c<global_columns; c++)
			{

				int z =  global_history[(size-a)-1][b][c];
				global_history[(size-a)][b][c] = z;
			}
		}
	}

	/* Insert the new generation */

	for (int d=0; d<global_rows; d++)
	{
		for (int e=0; e<global_columns; e++)
		{
			global_history[0][d][e] = field[d][e];
		}
	}	
}

/*
 *	Return the layer in history where the pattern was found. Returns -1 if not found.
 */
int
checkHistory(int[][] field, int size)
{
	int layer;
	layer = size-1;		/* compensate for starting at 0 */
	
	while (layer >= 0)
	{
		if (global_history[layer][][] == field){return layer;}else{layer--;}
	}
	
	return (-1);
}

/*
 *	Prints the entire field to standard output.
 */
void
printField(int[][] field)
{
	/* Hide and reset cursor with ANSI-Escape-Codes */
	/* For more on this, please see http://en.wikipedia.org/wiki/ANSI_escape_code */

	write(CSI, "?25l");		/* ANSI-Magic: hide cursor */
	write(CSI, "0;0H");		/* ANSI-Magic: reset cursor */

	/* Actually print the field */

	for (int i=0; i<=(global_rows + 1); i++)
	{
		
		for (int k=0; k<=(global_columns + 1); k++)
		{
			if ((i == 0) || (i == (global_rows + 1)))
			{
				write("-");
			}
			else if ((k == 0) || (k == (global_columns + 1)))
			{
				write("|");
			}
			else
			{
				/* Distinguish between "dead" (0) and "living" (1) cells */

				if (field[i-1][k-1] == 0)
				{
					write(" ");	/* It's dead, Jim! */
				}
				else
				{
					write("X");	/* It's alive! */
				}
			}
		}

		writefln("");

	}

	writef("Generation: %d", global_generations);
	writefln(info);

	write(CSI, "?25h");	/* ANSI-Magic: show cursor again */	
}

/*	COMMENT:
 *	Returns the number of living cells neighbouring the indicated one.
 *
 *	ooo	~~> x = cell with coordinates (x,y)
 *	oxo	~~> o = neighbouring cell
 *	ooo
 */
int
getLivingNeighbours(int[][] currentField, int x, int y)
{
	/* This works correctly. DO. NOT. TOUCH. */

	int count;
	count = 0;                                                                                                        /* POSITION: */

	if ( currentField[(x+1) % global_rows][y] == 1 ) {count++;}                                                       /* right _ same */
	if ( currentField[x][(y+1) % global_columns] == 1 ) {count++;}                                                    /* same  _ down */
	if ( currentField[(x+1) % global_rows][(y+1) % global_columns] == 1 ) {count++;}                                  /* right _ down */

	if ( currentField[((x+global_rows)-1) % global_rows][y] == 1 ) {count++;}                                         /* left  _ same */
	if ( currentField[x][((y+global_columns)-1) % global_columns] == 1 ) {count++;}                                   /* same  _ up   */
	if ( currentField[((x+global_rows)-1) % global_rows][((y+global_columns)-1) % global_columns] == 1 ) {count++;}	  /* left  _ up   */

	if ( currentField[((x+global_rows)-1) % global_rows][(y+1) % global_columns] == 1 ) {count++;}                    /* left  _ down */
	if ( currentField[(x+1) % global_rows][((y+global_columns)-1) % global_columns] == 1 ) {count++;}                 /* right _ up   */

	return count;
}

int[][]
computeNextGeneration(int[][] oldField)
{
	int[][] nextGen = new int[][](global_rows, global_columns);

	for (int i=0; i<global_rows; i++)		/* I am not sure wether this is actually necessary */
	{
		for (int j=0; j<global_columns; j++)
		{
			nextGen[i][j] = 0;	
		}
	}

	for (int a=0; a<global_rows; a++)
	{
		for (int b=0; b<global_columns; b++)
		{
			int count;
			count = getLivingNeighbours(oldField, a, b);

			if (oldField[a][b] == 0)	/* used to be dead and ... */
			{
				if (count == 3)
				{
					nextGen[a][b] = 1;	/* ... becomes alive! */
				}
				else
				{
					nextGen[a][b] = 0;	/* ... stayes dead! */				
				}
			}
			else				/* used to be alive and ... */
			{
				if (count < 2)
				{
					nextGen[a][b] = 0;	/* ... dies of loneliness! */
				}
				else if (count > 3)
				{
					nextGen[a][b] = 0;	/* ... dies of overpopulation! */				
				}
				else
				{
					nextGen[a][b] = 1;	/* ... stayes alive! */				
				}
			}
		}
	}


	if (info == "")
	{
		int hist;
		hist = checkHistory(nextGen, global_history_size);
	
		if (hist == 0)
		{
			generations_freeze = true;
			loop = false;
			info = " ~~> game reached a stable state.";
		}
		else if (hist > 0)
		{
			generations_freeze = true;
			info = " ~~> game reached an oscillating state with a cycle of " ~ to!string(hist+1) ~ " generations.";
		}
	}

	pushGeneration(nextGen, global_history_size);

	return nextGen;
}

/* 
 *	Places the freshly computed new generation into the global field variable.
 */
void
placeNextGeneration(int[][] nextField)
{
	for (int i=0; i<global_rows; i++)
	{
		for (int j=0; j<global_columns; j++)
		{
			global_field[i][j] = nextField[i][j];
		}
	}
}

void
main(string[] args)
{

	/* Clear screen properly using magic */

	write(CSI, "2J");		/* ANSI-Magic: clear screen */
	write(CSI, "0;0H");		/* ANSI-Magic: reset cursor */

	/* Use command-line-arguments */

	global_rows = to!int(args[1]);
	global_columns = to!int(args[2]);
	global_history_size = to!int(args[3]);
	global_interval_length = to!int(args[4]);

	global_generations = 0;
	generations_freeze = false;
	loop = true;
	info = "";

	/* create and initialise field and history. */

	global_field = new int[][](global_rows, global_columns);
	global_history = new int[][][](global_history_size, global_rows, global_columns);

	for (int i=0; i<global_rows; i++)
	{
		for (int j=0; j<global_columns; j++)
		{
			auto q = dice(50, 50);
			global_field[i][j] = q;	
		}
	}

	/* Fill the history */
	for (int q=0; q<10; q++)
	{
		pushGeneration(global_field, global_history_size);
	}

	/* Input Glider */
	/*
	global_field[10][10] = 1;
	global_field[10][11] = 1;
	global_field[10][12] = 1;
	global_field[9][12] = 1;
	global_field[8][11] = 1;
	*/

	/* Input Glider Cannon */ /*
	
	global_field[6][2] = 1;
	global_field[6][3] = 1;
	global_field[7][2] = 1;
	global_field[7][3] = 1;

	global_field[6][12] = 1;
	global_field[7][12] = 1;
	global_field[8][12] = 1;
	global_field[5][13] = 1;
	global_field[4][14] = 1;
	global_field[4][15] = 1;
	global_field[9][13] = 1;
	global_field[10][14] = 1;
	global_field[10][15] = 1;

	global_field[7][16] = 1;

	global_field[7][18] = 1;
	global_field[7][19] = 1;
	global_field[6][18] = 1;
	global_field[8][18] = 1;
	global_field[5][17] = 1;
	global_field[9][17] = 1;

	global_field[6][22] = 1;
	global_field[6][23] = 1;
	global_field[5][22] = 1;
	global_field[5][23] = 1;
	global_field[4][22] = 1;
	global_field[4][23] = 1;
	global_field[7][24] = 1;
	global_field[3][24] = 1;
	global_field[2][26] = 1;
	global_field[3][26] = 1;
	global_field[7][26] = 1;
	global_field[8][26] = 1;

	global_field[4][36] = 1;
	global_field[4][37] = 1;
	global_field[5][36] = 1;
	global_field[5][37] = 1; */

	/* Input Explosion 

	global_field[15][15] = 1;
	global_field[14][15] = 1;
	global_field[16][15] = 1;
	global_field[14][16] = 1;
	global_field[16][16] = 1;
	global_field[14][17] = 1;
	global_field[16][17] = 1;	

	global_field[14][19] = 1;
	global_field[16][19] = 1;
	global_field[14][20] = 1;
	global_field[16][20] = 1;
	global_field[14][21] = 1;
	global_field[16][21] = 1;
	global_field[15][21] = 1;*/
	

	/* Main Loop */

	printField(global_field);
	Thread.sleep(dur!("msecs")(global_interval_length));

	while (loop)
	{
		placeNextGeneration(computeNextGeneration(global_field));
		if (!(generations_freeze)) {global_generations++;}		/* Do not keep counting generations if we have a stable or oscillating state */
		printField(global_field);
		
		Thread.sleep(dur!("msecs")(global_interval_length));
	}
}

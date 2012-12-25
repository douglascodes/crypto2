Brief:
This program was meant for me to use as a challenge to solve cryptograms from a web feed with a pretty good accuracy... At the least It would generate working solutions, and if possible generate funny ones that still worked within the context of the puzzle. It was also a chance for me to learn more TDD and using Rspec. I am very happy with the results so far.

Instructions:
To run just type "ruby ./lib/main.rb #" from the base directory. Where # is the number of the puzzle you want to solve, starting from 0. No argument causes it to solve all puzzles.

v2.0 Reversed course. Instead of trying to generate all possible letter combinations THEN checking em against the dictionary and the possibles letter lists, I just take all the words from the dictionary fitting these criteria.
		a. Same full letter length
		b. Same unique letter count (the number of characters used at least once.)
		c. The same pattern. Ex. a five letter word with all unique letters, pattern_matches all other 5 letter words with unique characters. BUT a 5 letter word with repeated character(s) must have that repetition in the same positions. See the Unique module > pattern_create method to learn more.

	This reversal of searching increased the speed by the mathematical constant "a helluva lot." Version 2.0 also utilizes whole word solution generating, the return of 'kill_singles' method, the incorporation of the author section into generating the solution, words are now objects as well, split the different classes into their own files, and reincorporated the full specs.

	"Better" dictionaries. And more of 'em. The full 130k word dictionary, the popular words 10k, the most popular words 1k, and a names dictionary.

v1.0: Finally overcame some of the difficulties created by hypenated and words with parantheses. The solver breaks words with hyphens into two words. And it uses ' as a letter in which there is only one possible alternative, itself. 

	It has the option to use a proper names list I obtained from the census website. I took the top 58k surnames. In a future version it will try and solve the author name using this.


How it works...
Two notes about terms used.
	I. "key" letters/words are those given by the puzzle. For clarity all aspects of the puzzle given are written in lowercase, all "SOLUTION" letters//words are written UPPERCASE.

	II. Possibles/possibilities are lists of letters, words, etc that are REMAINING to be true with the knowledge already gained from the puzzle. Example: "key letters" 'x' and 'r' appear in the puzzle "r xy xbrpo." 'r' can only be "I" or "A,"  so all other possibles are removed from the letter object 'r's possbiles list. The word object 'r' can only have the word possbilities of "I" or "A." As any good scrabble player knows, there are no two letter words starting with "C" or "V," so those are removed from 'x's possibles. So the third key word cannot be anything that starts with a 'C' or 'V.'  You can see, by simply continuing to eliminate possbilities, the puzzle quickly shrinks.

A: Downloads an XML file from a puzzle website. Or for testing just uses the test.xml file since it doesn't require an internet connection.

B: Splits each puzzle into the Cryptogram, Author, and Date and assigning them to a new puzzle object.

C: Works on each puzzle seperately. (or a specific one as specified on the command line)
"ruby ./bin/main.rb" for all
"ruby ./bin/main.rb 3" for the fourth puzzle (count starts at zero)
Right now for testing, the specific declaration yields to pry for further examination after the solving attempt.

D: The two word sets, Crypto_broken, and Author_Broken are mapped creating new Word objects with a related dictionary. Crypto starts with the full 130k word dictionary I have been working to perfect (perfect = Enough words to solve all puzzles, but not so many that it cannot eliminate anything.) Author starts with a proper name dictionary, SMITH.txt, which is a compilation of year 2000 US census data for all surnames in the USA recorded at least 100 times (http://www.census.gov/genealogy/www/data/2000surnames/index.html), first names also compiled from the Census' list of the top 200 first names for babies each decade since 1880, and some special things I have been adding that could be used in a 'name' such as "QUEEN," "JR,"SR" etc. Since Author names can include single initials, it lets them have A-Z as possibilities for single letter word objects, unlike the "sentence" part of the puzzle with can only have "A" or "I" as single letter word objects.

F: Combines both those hashes of Crypto and Author and then works on them.

G: Does a looping run through the full set of words 6 times. 
	1. Within that loop it looks at smaller words first. X = 1 to Unique_letter_length of the longest word. It won't work on a word until it is <= X. This lets the smaller words determine more about the puzzle quicker.
	2. After three full cycles it kills off letters from the letter list that it knows 100% are solved.
	3. After a few cycles of words with multiple possibilities it tries to use a smaller set of dictionaries, from least to most popular. 130k words > 10k Words > 1k words.

H. To determine if a word is valid it keeps track of the list of key letter possibilities. As it looks at the word it checks it's remaining possibiles against the remaining letter possbilies in a method called char matcher. It only keeps those words whose solution letters remain in the key letter's list.

I. Then it runs condense_true. Which is for updating each key letter occurring in that word. Basically I like to say it smashes all the words vertically resets the letter's possibles list.
How I visualize it:

S T A N D
L A M E R
R A S P Y
M U S T Y 
S T A P H ^^^ Before condense
_________
a b c d e = Key Word
---------
S T A N D vvv After condense
L A M E R
R U S P Y
M     T H
        

a.possibles = SLRM 
b.possbiles = TAU
c.possbiles = AMS
d.possbiles = NEPT
e.possbiles = DRYH

J. After running it's fill of loops, (6 for now). It takes a best guess at the puzzle using two different methods. Whole word solutions, using the word objects possbilities. And then for any other words, where a possbility was lost ( Mostly due to imperfections in the dictionary, or some really obscure name or word) it will try to solve with Letters, using a letter frequency chart to try and guess the most likely remaining letter. 
http://en.wikipedia.org/wiki/Letter_frequency 

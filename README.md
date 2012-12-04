Brief:
This program was meant for me to use as a challenge to solve cryptograms from a web feed with a pretty good accuracy... At the least It would generate working solutions, and if possible generate funny ones that still worked within the context of the puzzle. It was also a chance for me to learn more TDD and using Rspec. I am very happy with the results so far.

Instructions:
To run just type "ruby ./lib/main.rb #" from the base directory. Where # is the number of the puzzle you want to solve, starting from 0. No argument causes it to solve all puzzles.

v1.0: Finally overcame some of the difficulties created by hypenated and words with parantheses. The solver breaks words with hyphens into two words. And it uses ' as a letter in which there is only one possible alternative, itself. 

It has the option to use a proper names list I obtained from the census website. I took the top 58k surnames. In a future version it will try and solve the author name using this.


How it works...

A: It creates a dictionary from the Ispell open source dictionary, loads it into an array of hashes where each number of the array corresponds to the length of words in it. The dictionary did not include certain common short words so they are concatted to the dictionary before its sorted.

B: It reads the website http://threadbender.com/rss.xml and parses the puzzles into objects kept in the @p_list array. Seperating the dates and author sections from the puzzle.

C: It loops through each word in order of its unique letter count. 

D: For each word, it generates a list of possible words based on each encrypted letter's list of remaining "POSSIBLE" letters.

E: Checks all generated words against the known dictionaries and keeps those that respond to true.

F: Condenses the words known by the position of each letter, and uses those letters to make up the NEW list of possible letters for each encrypted one.
Every word shortens the list of possible letters. 

G: And it loops back over each word for every length possible...
1 letter words....
1 and then 2 letter words...
1 and 2 and 3 letter words...
1 and 2 and 3 and 4 letter words... etc
This was to shorten the length of calculations done on much larger words when possible letters could be learned by going back to previous words first.

H: Once it does the full word list 3 times in that looping pattern, it considers it as solved as possible.

I: It then reattaches the author section and substitutes letters in each list of "POSSIBLES" based on the popularity list. The pop list is a set of letters in the order of their frequency of use in common english. So that its guesses are a little more accurate than not guessing.
http://en.wikipedia.org/wiki/Letter_frequency 

running main.rb without argument will just try all puzzles.



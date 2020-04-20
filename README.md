This abomination is my current attempt to make a pull request manager for Bitbucket, using Polybar and Dmenu.

My shell scripting chops leave much to be desired at the moment, and I hacked this togther as quickly as I could.
So, while it works (for me anyway), this is a great example of terrible code that should never have been written.

# What it does:
Enables you to view a list of pull requests in Bitbucket that require review.

### Dependencies:
jq
dmenu
polybar
zsh (I'm having trouble with line endings in bash and use zsh as my main shell anyway)

##twitcrypt

This is an experiment in encrypted Twitter communications. Messages are encrypted with AES-256, and packed in Asian characters to make the data safe for transport. Messages can hold up to 144 bytes of data, though with further optimization, message length can probably be extended.

This is still beta software, so I would use caution with sensitive data until further reviews are completed - which is to say - DON'T EXPECT IT TO BE SECURE.

###Usage

* `./twitcrypt -dt <tweet url>` - Get's the content of the tweet and decrypts it. *Doesn't work at the moment*
* `./twitcrypt -ed` - This is primarily for testing; displays the encrypted message.
* `./twitcrypt -dd <message - optional>` - This is primarily for testing; decrypts the message.
    
For all options, you will be prompted for the key, so it is not logged to your shell's history. The `-ed` will prompt for the message, and `-dd` will prompt if no message is passed in.

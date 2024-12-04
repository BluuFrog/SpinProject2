typedef eMessage{ // Custom encrypted message datatype
    mtype key;
    mtype misc1;
    mtype misc2;
};

chan comms = [0] of { eMessage, mtype, int } // Channel takes an encrypted message, message number/type, and reciever ID

bool AliceConfirmed = false; // Flag to show that Alice has recived her nonce back from Bob
bool BobConfirmed = false; // Flag to show that Bob has recived her nonce back from Alice

active proctype Alice(){
    // setup
    eMessage sentMsg;
    eMessage recievedMsg;
    mtype myNonce;
    int connectionConfirmed = 0;
    int msgNumber;
    int recivedKey;
    int i;

    sentMsg.key = 1; // knows Bob's public key
    select(i : 1 .. 10); // random nonce
    sentMsg.misc1 = i;
    myNonce = i;
    sentMsg.misc2 = _pid; // agent ID

    // first rendezvous

    comms ! sentMsg (1, 1);

    // second rendezvous

    comms ? (recievedMsg, msgNumber, recivedKey);

    if
        :: (recivedKey != _pid) -> assert(false) // makes sure key is correct
        :: else -> skip
    fi;
    
    if
        :: (recievedMsg.misc1 != myNonce) -> assert(false) // makes sure nonce was sent back
        :: else -> skip
    fi;

    AliceConfirmed = true; // Alice knows that Bob had recieved and decrypted her nonce
    

    // third rendezvous

    sentMsg.misc1 = recievedMsg.misc2 // sends Bob's nonce back to prove the message was decrypted
    sentMsg.misc2 = -1; // ther part of the message not necessary
    comms ! sentMsg (3, 1);
}

active proctype Bob(){
    // setup
    eMessage sentMsg;
    eMessage recievedMsg;
    mtype myNonce;
    int connectionConfirmed = 0;
    int msgNumber;
    int recivedKey;
    int i;


    // first rendezvous

    comms ? (recievedMsg, msgNumber, recivedKey);

    if
        :: (recivedKey != 1) -> assert(false); // makes sure key is correct
        :: else -> skip
    fi;

    // second rendezvous

    sentMsg.key = 0; //knows Alice's public key
    sentMsg.misc1 = recievedMsg.misc1 // sends Alice's nonce back to prove the message was decrypted
    select(i : 1 .. 10); // random nonce
    sentMsg.misc2 = i;
    myNonce = i;

    comms ! sentMsg (2, 0);

    // third rendezvous

    comms ? (recievedMsg, msgNumber, recivedKey);

    if
        :: (recivedKey != _pid) -> assert(false) // makes sure key is correct
        :: else -> skip
    fi;
    
    if
        :: (recievedMsg.misc1 != myNonce) -> assert(false) // makes sure nonce was sent back
        :: else -> skip
    fi;

    BobConfirmed = true; // Bob knows that Alice had recieved and decrypted his nonce

}

ltl Finishes {[]<> (AliceConfirmed && BobConfirmed)}
//ltl AliceFinishes {[]<> (AliceConfirmed)}
//ltl BobFinishes {[]<> (BobConfirmed)}
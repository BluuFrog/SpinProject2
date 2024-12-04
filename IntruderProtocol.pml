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
        :: (recievedMsg.key != _pid) -> assert(false) // makes sure message has correct key
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
        :: (recievedMsg.key != 1) -> assert(false); // makes sure message has correct key
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
        :: (recievedMsg.key != _pid) -> assert(false) // makes sure message has correct key
        :: else -> skip
    fi;
    
    if
        :: (recievedMsg.misc1 != myNonce) -> assert(false) // makes sure nonce was sent back
        :: else -> skip
    fi;

    BobConfirmed = true; // Bob knows that Alice had recieved and decrypted his nonce

}

active proctype Intruder(){
    // setup
    eMessage sentMsg;
    eMessage recievedMsg;
    mtype myNonce;
    int msgNumber;
    int recivedKey;
    int i;
    int j;
    int k;
    
    // attempting to intercept

    comms ? (recievedMsg, msgNumber, recivedKey);

    // forwarding packet or creating a new packet and sending it

    select(j: 0 .. 1); // randomly picking the recipient of the message
    select(k: 0 .. 1); // randomly picking forward recived packet or make new packet

    sentMsg.key = recievedMsg.key; // making a new packet 
    sentMsg.misc1 = recievedMsg.misc1; 
    sentMsg.misc1 = recievedMsg.misc1;

    if
        :: (k == 0) -> comms ! recievedMsg (msgNumber, j) // forwards the message marked for process j
        :: (k == 1) -> comms ! sentMsg (msgNumber, j) // sends new packet to process j
        :: else -> skip
    fi;


}

ltl Finishes {[]<> (AliceConfirmed && BobConfirmed)}
//ltl AliceFinishes {[]<> (AliceConfirmed)}
//ltl BobFinishes {[]<> (BobConfirmed)}
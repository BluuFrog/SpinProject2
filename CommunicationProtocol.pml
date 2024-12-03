typedef eMessage{
    mtype key;
    mtype nonce;
    mtype ID;
};

chan comms = [0] of { eMessage, mtype, int }

active proctype Alice(){
    eMessage new1;
}

active proctype Bob(){
    eMessage new2;
}
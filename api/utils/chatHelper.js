export const getRoomId = (user1, user2) => {
    return [user1,user2].sort().join("_");
};

/**
 * Output:
 * getRoomId("Alice", "Bob"); // "Alice_Bob"
    getRoomId("Bob", "Alice"); // "Alice_Bob"
 
    - setting RoomId for two users
    - So no matter who starts the chat, the room ID stays the same. (despite who is the sender nor the receiver)
    
    Whe we do it? 
    - Prevents duplicate chat rooms (one for Alice→Bob, another for Bob→Alice).
    - Makes it easy to query messages in one consistent chat room.

 */



/*
Rule of Thumb:
export const → must be followed by an assignment (=).

export function → declares a named function directly.

Correct Ways: if using const
export const getRoomId = function(user1, user2) {
  // logic here
};

export const getRoomId = (user1, user2) => {
  // logic here
};
*/
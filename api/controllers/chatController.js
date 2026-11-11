import { chatRoom, fetchChatMessages } from '../services/chatServices.js';

export const getMessages = async (req, res) => {
  const { senderId, receiverId, currentUserId, page, limit } = req.query;

  const currentId = req.userId || currentUserId;
  const effectiveSenderId = senderId || currentId;
  const effectiveReceiverId = receiverId;

  if (!effectiveReceiverId) {
    return res.status(400).json({ message: 'receiverId is required' });
  }

  try {
    const messages = await fetchChatMessages({
      currentUserId: currentId,
      senderId: effectiveSenderId,
      receiverId: effectiveReceiverId,
      page: parseInt(page, 10) || 1,
      limit: parseInt(limit, 10) || 20,
    });

    return res.json(messages || []);
  } catch (error) {
    console.error('Error in getMessages controller:', error);
    return res.status(500).json({ message: 'Error fetching messages' });
  }
};

export const getChatRoom = async (req, res) => {
  try {
    const rooms = await chatRoom(req.userId);
    return res.json(rooms || []);
  } catch (error) {
    console.error('Error in getChatRoom controller:', error);
    return res.status(500).json({ message: 'Error fetching rooms' });
  }
};

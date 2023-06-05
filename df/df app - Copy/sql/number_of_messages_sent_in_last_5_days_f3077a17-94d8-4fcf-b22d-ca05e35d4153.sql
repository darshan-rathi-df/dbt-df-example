SELECT COUNT(*) AS num_messages_sent
FROM darshan_locals.Message
WHERE SentOn >= (EXTRACT(EPOCH FROM NOW()) * 1000) - (5 * 24 * 60 * 60 * 1000)
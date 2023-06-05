SELECT c."Name", COUNT(m."Id") / COUNT(DISTINCT c."Id") AS avg_messages_per_chat
FROM darshan_locals."Chat" c
JOIN darshan_locals."Message" m ON c."Id" = m."ChatId"
GROUP BY c."Name"
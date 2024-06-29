DROP function if exists chats.send_push_notification;

CREATE OR REPLACE FUNCTION chats.send_push_notification()
    RETURNS TRIGGER AS $$
DECLARE
    user_record RECORD;
BEGIN
    -- Loop through all users in the room except the author
    FOR user_record IN
        SELECT u.id, 
               CASE WHEN u."lastSeen" >= (EXTRACT(epoch FROM NOW()) * 1000 - 30000) THEN true ELSE false END AS online
        FROM chats.users u
        JOIN chats.rooms r ON r.id = NEW."roomId"
        WHERE u.id = ANY(r."userIds")
          AND u.id <> NEW."authorId"
    LOOP
        -- If the user is not online, send a push notification
        IF NOT user_record.online THEN
            PERFORM pg_notify('chat_push_notification', 
                json_build_object(
                    'text', NEW.text,
                    'author_id', NEW."authorId",
                    'user_id', user_record.id,
                    'room_id', NEW."roomId"
                )::text);
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER send_push_notification_trigger
    AFTER INSERT ON chats.messages
    FOR EACH ROW
    EXECUTE FUNCTION chats.send_push_notification();
create function get_unread_message_count(p_room_id bigint, p_user_id uuid) returns integer
    language plpgsql
as
$$
DECLARE
    last_read bigint;
    unread_count integer;
BEGIN
    -- Get the last read time for the user in this room
    SELECT (last_read_times->>(p_user_id::text))::bigint
    INTO last_read
    FROM chats.rooms
    WHERE id = p_room_id;

    -- If last_read_times is null or doesn't have an entry for this user,
    -- count all messages as unread
    IF last_read IS NULL THEN
        SELECT COUNT(*)
        INTO unread_count
        FROM chats.messages
        WHERE "roomId" = p_room_id;
    ELSE
        SELECT COUNT(*)
        INTO unread_count
        FROM chats.messages
        WHERE "roomId" = p_room_id AND "createdAt" > last_read
        AND "authorId" != p_user_id;
    END IF;

    RETURN unread_count;
END;
$$;

alter function get_unread_message_count(bigint, uuid) owner to postgres;

grant execute on function get_unread_message_count(bigint, uuid) to anon;

grant execute on function get_unread_message_count(bigint, uuid) to authenticated;

grant execute on function get_unread_message_count(bigint, uuid) to service_role;


create function is_auth() returns boolean
    security definer
    language plpgsql
as
$$
BEGIN
  return auth.uid() IS NOT NULL;
end;
$$;

alter function is_auth() owner to postgres;

grant execute on function is_auth() to anon;

grant execute on function is_auth() to authenticated;

grant execute on function is_auth() to service_role;


create function is_chat_member(room_id bigint) returns boolean
    security definer
    language plpgsql
as
$$
DECLARE
  members uuid[];
BEGIN
    SELECT "userIds" INTO members
      FROM chats.rooms
      WHERE id = room_id;
  return chats.is_member(members);
end;
$$;

alter function is_chat_member(bigint) owner to postgres;

grant execute on function is_chat_member(bigint) to anon;

grant execute on function is_chat_member(bigint) to authenticated;

grant execute on function is_chat_member(bigint) to service_role;


create function is_member(members uuid[]) returns boolean
    security definer
    language plpgsql
as
$$
BEGIN
  return auth.uid() = ANY(members);
end;
$$;

alter function is_member(uuid[]) owner to postgres;

grant execute on function is_member(uuid[]) to anon;

grant execute on function is_member(uuid[]) to authenticated;

grant execute on function is_member(uuid[]) to service_role;



create function is_owner(user_id uuid) returns boolean
    security definer
    language plpgsql
as
$$
BEGIN
  return auth.uid() = user_id;
end;
$$;

alter function is_owner(uuid) owner to postgres;

grant execute on function is_owner(uuid) to anon;

grant execute on function is_owner(uuid) to authenticated;

grant execute on function is_owner(uuid) to service_role;


create function leave_room(p_room_id bigint, p_user_id text) returns jsonb
    language plpgsql
as
$$DECLARE
    v_room_data chats.rooms%ROWTYPE;
    v_metadata jsonb;
    v_left_users jsonb;
    v_user_uuid uuid;
BEGIN
    -- Validate user UUID input
    BEGIN
        v_user_uuid := p_user_id::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Invalid user UUID format');
    END;

    -- Get current room data
    SELECT * INTO v_room_data
    FROM chats.rooms
    WHERE id = p_room_id;

    IF v_room_data IS NULL THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Room not found');
    END IF;

    -- Check if the user is in the room
    IF NOT (v_user_uuid = ANY(v_room_data."userIds")) THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'User is not in the room');
    END IF;

    v_metadata := COALESCE(v_room_data.metadata, '{}'::jsonb);
    v_left_users := COALESCE(v_metadata->'leftUsers', '[]'::jsonb);

    -- Add user to leftUsers in metadata if not already there
    IF NOT (v_user_uuid::text IN (SELECT jsonb_array_elements_text(v_left_users))) THEN
        v_left_users := v_left_users || to_jsonb(v_user_uuid::text);
    END IF;

    -- Update metadata
    v_metadata := jsonb_set(v_metadata, '{leftUsers}', v_left_users);
    v_metadata := jsonb_set(v_metadata, '{lastLeftUserId}', to_jsonb(v_user_uuid::text));

    -- Check if all users have left
    IF jsonb_array_length(v_left_users) = array_length(v_room_data."userIds", 1) THEN
        -- Delete the room if all users have left
        DELETE FROM chats.rooms WHERE id = p_room_id;
        RETURN jsonb_build_object('status', 'success', 'message', 'All users left. Room deleted');
    END IF;

    -- Update the room
    UPDATE chats.rooms
    SET
        "updatedAt" = (extract(epoch from now()) * 1000)::bigint,
        metadata = v_metadata
    WHERE id = p_room_id;

    RETURN jsonb_build_object('status', 'success', 'message', 'User left the room');
EXCEPTION
    WHEN others THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'An unexpected error occurred: ' || SQLERRM);
END;$$;

alter function leave_room(bigint, text) owner to postgres;

grant execute on function leave_room(bigint, text) to anon;

grant execute on function leave_room(bigint, text) to authenticated;

grant execute on function leave_room(bigint, text) to service_role;

create function update_last_read_time(p_room_id bigint, p_user_id uuid, p_last_read_time bigint) returns void
    language plpgsql
as
$$
BEGIN
    UPDATE chats.rooms
    SET last_read_times = COALESCE(last_read_times, '{}'::jsonb) || 
                          jsonb_build_object(p_user_id::text, p_last_read_time)
    WHERE id = p_room_id;
END;
$$;

alter function update_last_read_time(bigint, uuid, bigint) owner to postgres;

grant execute on function update_last_read_time(bigint, uuid, bigint) to anon;

grant execute on function update_last_read_time(bigint, uuid, bigint) to authenticated;

grant execute on function update_last_read_time(bigint, uuid, bigint) to service_role;






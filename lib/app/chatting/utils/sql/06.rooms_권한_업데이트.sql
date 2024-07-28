방나가긱 구현을 위해 아래와 같이 쿼리 실행

-- Supabase AI is experimental and may produce incorrect answers
-- Always verify the output before executing

-- Enable RLS on the rooms table;
alter table chats.rooms enable row level security;

-- Policy to allow users to select rooms they are a part of;
create policy "Users can view rooms they are a part of" on chats.rooms for
select
  using (auth.uid ()::uuid = any (chats.rooms."userIds"));

-- Policy to allow users to insert new rooms;
create policy "Users can create rooms" on chats.rooms for insert
with
  check (auth.uid ()::uuid = any (chats.rooms."userIds"));

-- Policy to allow users to update rooms they are a part of;
create policy "Users can update rooms they are a part of" on chats.rooms
for update
  using (auth.uid ()::uuid = any (chats.rooms."userIds"))
with
  check (auth.uid ()::uuid = any (chats.rooms."userIds"));

-- Policy to allow users to delete rooms they are a part of;
create policy "Users can delete rooms they are a part of" on chats.rooms for delete using (auth.uid ()::uuid = any (chats.rooms."userIds"));





DECLARE
    v_user_ids uuid[];
    v_room_type text;
    ts_in_milliseconds bigint;
BEGIN
    SELECT EXTRACT(epoch FROM NOW()) * 1000 INTO ts_in_milliseconds;

    -- Get current userIds and room type
    SELECT "userIds", type INTO v_user_ids, v_room_type
    FROM chats.rooms
    WHERE id = p_room_id;

    -- Check if the user is in the room
    IF NOT (p_user_id = ANY(v_user_ids)) THEN
        RAISE EXCEPTION 'User is not in the room';
    END IF;

    -- If it's a direct chat, we don't remove the user from userIds
    IF v_room_type = 'direct' THEN
        -- Update metadata to indicate the user has left
        UPDATE chats.rooms
        SET 
            "updatedAt" = ts_in_milliseconds,
            metadata = jsonb_set(
                coalesce(metadata, '{}'::jsonb),
                '{lastLeftUserId}',
                to_jsonb(p_user_id::text)
            )
        WHERE id = p_room_id;
    ELSE
        -- For group chats, remove the user from userIds
        v_user_ids := array_remove(v_user_ids, p_user_id);

        -- Update the room
        UPDATE chats.rooms
        SET 
            "userIds" = v_user_ids,
            "updatedAt" = ts_in_milliseconds,
            metadata = jsonb_set(
                coalesce(metadata, '{}'::jsonb),
                '{lastLeftUserId}',
                to_jsonb(p_user_id::text)
            )
        WHERE id = p_room_id;

        -- If there are no users left in the group chat, delete it
        IF array_length(v_user_ids, 1) IS NULL THEN
            DELETE FROM chats.rooms WHERE id = p_room_id;
        END IF;
    END IF;
END;

create function handle_new_user() returns trigger
    security definer
    SET search_path = public
    language plpgsql
as
$$
DECLARE
    ts_in_milliseconds bigint;
BEGIN
  SELECT EXTRACT(epoch FROM NOW()) * 1000 INTO ts_in_milliseconds;
  insert into chats.users (id, "createdAt", "updatedAt", "lastSeen")
  values (new.id, ts_in_milliseconds, ts_in_milliseconds, ts_in_milliseconds);
  return new;
end;
$$;

alter function handle_new_user() owner to postgres;

grant execute on function handle_new_user() to anon;

grant execute on function handle_new_user() to authenticated;

grant execute on function handle_new_user() to service_role;



create function set_message_status_to_sent() returns trigger
    language plpgsql
as
$$
BEGIN
    NEW.status := 'sent';
    RETURN NEW;
END;
$$;

alter function set_message_status_to_sent() owner to postgres;

grant execute on function set_message_status_to_sent() to anon;

grant execute on function set_message_status_to_sent() to authenticated;

grant execute on function set_message_status_to_sent() to service_role;



create function update_last_messages() returns trigger
    language plpgsql
as
$$
DECLARE
    ts_in_milliseconds bigint;
BEGIN
    SELECT EXTRACT(epoch FROM NOW()) * 1000 INTO ts_in_milliseconds;
    UPDATE chats.rooms
    SET "updatedAt" = ts_in_milliseconds,
        "lastMessages" = jsonb_build_array(NEW)
        WHERE id = NEW."roomId";
    RETURN NEW;
END;
$$;

alter function update_last_messages() owner to postgres;

grant execute on function update_last_messages() to anon;

grant execute on function update_last_messages() to authenticated;

grant execute on function update_last_messages() to service_role;

